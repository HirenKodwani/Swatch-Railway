import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import logger from '../logger/index.js';

class StationBillingService {
  // ─── Generate Billing Support Pack ────────────────────────────────────────
  async generateBillingSupportPack(user, data) {
    const { contractId, stationId, month, year } = data;
    if (!contractId || !stationId || !month || !year) {
      throw new ValidationError('contractId, stationId, month, and year are required');
    }

    const contractDoc = await db.collection('contracts').doc(contractId).get();
    if (!contractDoc.exists) throw new NotFoundError('Contract not found');
    const contractData = contractDoc.data();

    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');
    const stationName = stationDoc.data().stationName || '';

    const monthPad = String(month).padStart(2, '0');
    const startDate = `${year}-${monthPad}-01`;
    const endDate = `${year}-${monthPad}-31`;

    // Parallel fetch of all data sources
    const [
      attendanceSnap, activitySnap, scorecardSnap,
      complaintSnap, feedbackSnap, inspectionSnap, machineSnap,
    ] = await Promise.all([
      db.collection('station_attendance').where('stationId', '==', stationId).where('date', '>=', startDate).where('date', '<=', endDate).get(),
      db.collection('station_daily_activities').where('stationId', '==', stationId).where('date', '>=', startDate).where('date', '<=', endDate).get(),
      db.collection('daily_scorecards').where('stationId', '==', stationId).where('date', '>=', startDate).where('date', '<=', endDate).get(),
      db.collection('complaints').where('stationId', '==', stationId).where('createdAt', '>=', startDate).get(),
      db.collection('station_feedback').where('stationId', '==', stationId).get(),
      db.collection('inspections').where('stationId', '==', stationId).get(),
      db.collection('machineDeployments').where('stationId', '==', stationId).get(),
    ]);

    // Attendance Summary
    const attendanceRecords = [];
    attendanceSnap.forEach(doc => attendanceRecords.push(doc.data()));
    const presentCount = attendanceRecords.filter(r => ['present', 'late'].includes(r.status)).length;
    const absentCount = attendanceRecords.filter(r => r.status === 'absent').length;
    const uniqueDates = [...new Set(attendanceRecords.map(r => r.date))].length;
    const avgDailyManpower = uniqueDates > 0 ? Math.round(presentCount / uniqueDates) : 0;
    const attendanceSummary = {
      totalDaysRecorded: uniqueDates,
      totalAttendanceEntries: attendanceRecords.length,
      totalPresent: presentCount,
      totalAbsent: absentCount,
      averageDailyManpower: avgDailyManpower,
      attendancePercentage: attendanceRecords.length > 0 ? Math.round((presentCount / attendanceRecords.length) * 100) : 0,
    };

    // Activity Summary
    const activities = [];
    activitySnap.forEach(doc => activities.push(doc.data()));
    const actSummary = { total: activities.length, approved: 0, completed: 0, rejected: 0, pending: 0, missed: 0 };
    activities.forEach(a => { if (actSummary[a.status] !== undefined) actSummary[a.status]++; });
    const activityCompletionRate = actSummary.total > 0
      ? Math.round(((actSummary.approved + actSummary.completed) / actSummary.total) * 100) : 0;

    // Scorecard Summary
    const scorecards = [];
    scorecardSnap.forEach(doc => scorecards.push(doc.data()));
    const totalScore = scorecards.reduce((s, c) => s + (c.overallStationScore || 0), 0);
    const avgScore = scorecards.length > 0 ? Math.round((totalScore / scorecards.length) * 10) / 10 : 0;
    const gradeMap = { A: 0, B: 0, C: 0, D: 0 };
    scorecards.forEach(c => { if (gradeMap[c.grade] !== undefined) gradeMap[c.grade]++; });
    const scorecardSummary = {
      daysWithScorecard: scorecards.length,
      averageScore: avgScore,
      gradeDistribution: gradeMap,
      certified: scorecards.every(c => c.certified),
    };

    // Complaint Summary
    const complaints = [];
    complaintSnap.forEach(doc => {
      const d = doc.data();
      const created = d.createdAt || '';
      if (created >= startDate && created <= endDate + 'T23:59:59') complaints.push(d);
    });
    const cmpSummary = { total: complaints.length, closed: 0, open: 0, pending: 0, rejected: 0 };
    complaints.forEach(c => {
      if (c.status === 'CLOSED') cmpSummary.closed++;
      else if (c.status === 'REJECTED') cmpSummary.rejected++;
      else if (['REPORTED', 'ASSIGNED', 'IN_PROGRESS'].includes(c.status)) cmpSummary.open++;
      else cmpSummary.pending++;
    });

    // Feedback Summary
    const feedbackRecords = [];
    feedbackSnap.forEach(doc => {
      const d = doc.data();
      if ((d.createdAt || '') >= startDate) feedbackRecords.push(d);
    });
    const totalRating = feedbackRecords.reduce((s, f) => s + (f.rating || 0), 0);
    const feedbackSummary = {
      totalFeedbacks: feedbackRecords.length,
      averageRating: feedbackRecords.length > 0 ? Math.round((totalRating / feedbackRecords.length) * 10) / 10 : 0,
      negativeFeedbacks: feedbackRecords.filter(f => f.isNegative).length,
    };

    // Penalty / Deduction Computation
    const billingRuleSnap = await db.collection('billingRules').where('contractId', '==', contractId).limit(1).get();
    let penalties = { totalPenaltyAmount: 0, deductions: [] };

    if (!billingRuleSnap.empty) {
      const rules = billingRuleSnap.docs[0].data();
      const contractValue = contractData.contractValue || 0;
      const monthlyBase = contractValue / 12;

      // Attendance-based penalty
      if (attendanceSummary.attendancePercentage < 90 && rules.attendancePenaltyRate) {
        const shortfall = 90 - attendanceSummary.attendancePercentage;
        const penaltyAmt = (shortfall / 100) * monthlyBase * (rules.attendancePenaltyRate || 0.01);
        penalties.deductions.push({ reason: 'Attendance Shortfall', percentage: shortfall, amount: Math.round(penaltyAmt) });
        penalties.totalPenaltyAmount += Math.round(penaltyAmt);
      }

      // Score-based penalty
      if (avgScore < 70 && rules.scorePenaltyRate) {
        const shortfall = 70 - avgScore;
        const penaltyAmt = (shortfall / 100) * monthlyBase * (rules.scorePenaltyRate || 0.02);
        penalties.deductions.push({ reason: 'Cleanliness Score Below 70%', percentage: shortfall, amount: Math.round(penaltyAmt) });
        penalties.totalPenaltyAmount += Math.round(penaltyAmt);
      }
    }

    // Machine downtime summary
    const machines = [];
    machineSnap.forEach(doc => machines.push(doc.data()));
    const machineDowntime = machines.filter(m => m.status === 'MAINTENANCE').length;

    const billableAmount = Math.max(0,
      (contractData.contractValue / 12) - penalties.totalPenaltyAmount
    );

    const ref = db.collection('station_billing_packs').doc();
    const now = new Date().toISOString();
    const pack = {
      uid: ref.id,
      contractId, stationId, stationName,
      month: parseInt(month), year: parseInt(year),
      contractNumber: contractData.contractNumber || '',
      contractorName: contractData.contractorName || contractData.entityName || '',
      monthlyContractValue: Math.round(contractData.contractValue / 12),
      attendanceSummary,
      activitySummary: { ...actSummary, completionRate: activityCompletionRate },
      scorecardSummary,
      complaintSummary: cmpSummary,
      feedbackSummary,
      machineSummary: { total: machines.length, inMaintenance: machineDowntime, deployed: machines.filter(m => m.status === 'DEPLOYED').length },
      penalties,
      billableAmount,
      status: 'DRAFT',
      complianceChecklist: {
        attendanceSheetAttached: false,
        wagesheetAttached: false,
        bankStatementAttached: false,
        policeVerificationAttached: false,
        medicalCertificateAttached: false,
        biometricSheetAttached: false,
        scorecardAttached: scorecardSummary.daysWithScorecard > 0,
        gstInvoiceAttached: false,
      },
      generatedBy: user.uid,
      generatedByName: user.fullName || '',
      generatedAt: now,
      createdAt: now, updatedAt: now,
    };

    await ref.set(pack);
    logger.info('StationBilling', `Billing pack generated: ${ref.id} for ${stationId} ${month}/${year}`);
    return { message: 'Billing support pack generated', uid: ref.id, pack };
  }

  // ─── Get Pack by ID ───────────────────────────────────────────────────────
  async getPackById(uid) {
    const doc = await db.collection('station_billing_packs').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Billing pack not found');
    return { id: doc.id, ...doc.data() };
  }

  // ─── List Packs ───────────────────────────────────────────────────────────
  async listPacks(query = {}) {
    const { contractId, stationId, month, year, status, limit = 50 } = query;
    let q = db.collection('station_billing_packs');
    if (contractId) q = q.where('contractId', '==', contractId);
    if (stationId) q = q.where('stationId', '==', stationId);
    if (month) q = q.where('month', '==', parseInt(month));
    if (year) q = q.where('year', '==', parseInt(year));
    if (status) q = q.where('status', '==', status);
    const snapshot = await q.orderBy('createdAt', 'desc').limit(parseInt(limit)).get();
    const packs = [];
    snapshot.forEach(doc => packs.push({ id: doc.id, ...doc.data() }));
    return { count: packs.length, packs };
  }

  // ─── Update Compliance Checklist ──────────────────────────────────────────
  async updateCompliance(uid, checklist, user) {
    const ref = db.collection('station_billing_packs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Billing pack not found');
    await ref.update({
      complianceChecklist: checklist,
      updatedAt: new Date().toISOString(),
      updatedBy: user.uid,
    });
    return { message: 'Compliance checklist updated', uid };
  }

  // ─── Submit Pack for Review ───────────────────────────────────────────────
  async submitPack(uid, user) {
    const ref = db.collection('station_billing_packs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Billing pack not found');
    if (doc.data().status !== 'DRAFT') throw new ValidationError('Only DRAFT packs can be submitted');
    await ref.update({ status: 'SUBMITTED', submittedBy: user.uid, submittedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Billing pack submitted for review', uid };
  }

  // ─── Approve / Reject Pack ────────────────────────────────────────────────
  async approvePack(uid, user) {
    const ref = db.collection('station_billing_packs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Billing pack not found');
    if (doc.data().status !== 'SUBMITTED') throw new ValidationError('Only SUBMITTED packs can be approved');
    await ref.update({ status: 'APPROVED', approvedBy: user.uid, approvedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Billing pack approved', uid };
  }

  async rejectPack(uid, reason, user) {
    const ref = db.collection('station_billing_packs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Billing pack not found');
    if (!reason) throw new ValidationError('Rejection reason is required');
    await ref.update({ status: 'REJECTED', rejectionReason: reason, rejectedBy: user.uid, rejectedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Billing pack rejected', uid };
  }
}

export const stationBillingService = new StationBillingService();
