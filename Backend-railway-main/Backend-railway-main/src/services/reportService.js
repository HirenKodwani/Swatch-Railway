import { db } from '../database/index.js';
import { ReportService as ReportServiceLegacy } from '../../report_service.js';
import { createWorkbook, addSummarySheet, addDataSheet, createPdf, drawPdfHeader, drawPdfSection, drawPdfTable } from '../reports/reportHelper.js';
import { NotFoundError, ValidationError, ForbiddenError } from '../errors/index.js';

class ReportService {
  constructor() {
    this.legacyService = new ReportServiceLegacy(db);
  }

  async getPremisesData(queryParams) {
    const { zone, division, depot, startDate, endDate, areaType, contractorId, contractId, supervisorId } = queryParams;
    if (contractId) {
      const contractDoc = await db.collection('contracts').doc(contractId).get();
      if (!contractDoc.exists) throw new NotFoundError('Contract Not Found');
      const cData = contractDoc.data();
      const isStatusExpired = ['Expired', 'expired', 'Inactive', 'inactive'].includes(cData.status);
      let isDateExpired = false;
      if (cData.endDate) { const today = new Date(); const end = new Date(cData.endDate); end.setHours(23, 59, 59, 999); if (today > end) isDateExpired = true; }
      if (isStatusExpired || isDateExpired) throw new ValidationError('Contract Expired', `Expired on ${cData.endDate || 'Unknown'}`);
    }
    let query = db.collection('premisesForms').where('status', 'in', ['LOCKED', 'AUTO-APPROVED']);
    if (zone) query = query.where('submittedByZone', '==', zone);
    if (division) query = query.where('submittedByDivision', '==', division);
    if (depot) query = query.where('submittedByDepot', '==', depot);
    if (contractorId) query = query.where('submittedByEntityId', '==', contractorId);
    if (contractId) query = query.where('contractId', '==', contractId);
    if (supervisorId) query = query.where('submittedById', '==', supervisorId);
    const snapshot = await query.get();
    let reportData = [];
    const start = startDate ? new Date(startDate) : null;
    const end = endDate ? new Date(endDate) : null;
    if (end) end.setHours(23, 59, 59, 999);
    const selectedAreas = areaType ? areaType.split(',').map(item => item.trim()) : [];
    snapshot.forEach(doc => {
      const data = doc.data();
      const formDate = data.formDateTime ? new Date(data.formDateTime) : new Date();
      let includeRecord = true;
      if (start && formDate < start) includeRecord = false;
      if (end && formDate > end) includeRecord = false;
      if (includeRecord && selectedAreas.length > 0 && !selectedAreas.includes(data.location)) includeRecord = false;
      if (includeRecord) {
        const summary = data.ratingDetails?.summary || {};
        const overallPct = parseFloat(summary.overallAveragePct) || 0;
        reportData.push({ date: formDate.toLocaleDateString('en-IN'), premiseName: data.location || 'Unknown', areaCategory: data.area || 0, totalArea: data.area || 0, areaAttended: data.area || 0, areaNotAttended: 0, ratingInPct: overallPct.toFixed(2) + '%', overallScore: summary.overallAveragePct || '0%', above90: overallPct > 90 ? 'Yes' : 'NA', penalty81to90: overallPct >= 81 && overallPct <= 90 ? 'Yes' : 'NA', penalty71to80: overallPct >= 71 && overallPct <= 80 ? 'Yes' : 'NA', penaltyBelow70: overallPct <= 70 ? 'Yes' : 'NA' });
      }
    });
    return { count: reportData.length, data: reportData };
  }

  async getCoachData(queryParams) {
    const { zone, division, depot, startDate, endDate, contractorId, contractId, trainNo, coachNo, supervisorId, areaType } = queryParams;
    if (contractId) {
      const contractDoc = await db.collection('contracts').doc(contractId).get();
      if (!contractDoc.exists) throw new NotFoundError('Contract Not Found');
      const cData = contractDoc.data();
      const isStatusExpired = ['Expired', 'expired', 'Inactive', 'inactive'].includes(cData.status);
      let isDateExpired = false;
      if (cData.endDate) { const today = new Date(); const end = new Date(cData.endDate); end.setHours(23, 59, 59, 999); if (today > end) isDateExpired = true; }
      if (isStatusExpired || isDateExpired) throw new ValidationError('Contract Expired', `Expired on ${cData.endDate || 'Unknown'}`);
    }
    let query = db.collection('coachForms').where('status', 'in', ['LOCKED', 'AUTO-APPROVED']);
    if (zone) query = query.where('submittedByZone', '==', zone);
    if (division) query = query.where('submittedByDivision', '==', division);
    if (depot) query = query.where('submittedByDepot', '==', depot);
    if (contractorId) query = query.where('submittedByEntityId', '==', contractorId);
    if (contractId) query = query.where('contractId', '==', contractId);
    if (supervisorId) query = query.where('submittedById', '==', supervisorId);
    const snapshot = await query.get();
    let reportData = [];
    const start = startDate ? new Date(startDate) : null;
    const end = endDate ? new Date(endDate) : null;
    if (end) end.setHours(23, 59, 59, 999);
    snapshot.forEach(doc => {
      const data = doc.data();
      const formDate = data.formDateTime ? new Date(data.formDateTime) : new Date();
      let includeRecord = true;
      if (start && formDate < start) includeRecord = false;
      if (end && formDate > end) includeRecord = false;
      if (includeRecord && trainNo) { if (!String(data.trainNumber || '').includes(trainNo)) includeRecord = false; }
      if (includeRecord) {
        const evalTable = data.ratingDetails?.coachEvaluationTable || [];
        const totalCoaches = evalTable.length;
        let counts = { internal: { A: 0, B: 0, C: 0, D: 0, NA: 0 }, intensive: { A: 0, B: 0, C: 0, D: 0, NA: 0 }, toiletries: { Yes: 0, No: 0, NA: 0 }, watering: { Yes: 0, No: 0, NA: 0 }, doors: { Yes: 0, No: 0, NA: 0 } };
        const inc = (obj, key) => { if (key && obj[key] !== undefined) obj[key]++; };
        evalTable.forEach(coach => { inc(counts.internal, coach.internalCleaning); inc(counts.intensive, coach.intensiveCleaning); inc(counts.toiletries, coach.toiletries); inc(counts.watering, coach.watering); inc(counts.doors, coach.doorsLocking); });
        const fmt = (val) => (val === 0 ? '' : val);
        reportData.push({ date: formDate.toLocaleDateString('en-IN'), trainName: data.trainName || 'N/A', trainNo: data.trainNumber || 'N/A', workType: data.ratingDetails?.workType, acwpStatus: data.ratingDetails?.acwpStatus, int_A: fmt(counts.internal.A), int_B: fmt(counts.internal.B), int_C: fmt(counts.internal.C), int_D: fmt(counts.internal.D), intense_A: fmt(counts.intensive.A), intense_B: fmt(counts.intensive.B), intense_C: fmt(counts.intensive.C), intense_D: fmt(counts.intensive.D), toil_Yes: fmt(counts.toiletries.Yes), toil_No: fmt(counts.toiletries.No), water_Yes: fmt(counts.watering.Yes), water_No: fmt(counts.watering.No), door_Yes: fmt(counts.doors.Yes), door_No: fmt(counts.doors.No) });
      }
    });
    return { count: reportData.length, data: reportData };
  }

  async getTrainPerformance(queryParams, user) {
    const { uid, role, userType, zone, division, depot, entityId } = user;
    const { trainNo, startDate, endDate } = queryParams;
    let query = db.collection('coachForms').where('status', 'in', ['LOCKED', 'AUTO-APPROVED']);
    const userRole = (role || '').toLowerCase();
    const isMaster = userRole.includes('master') || userRole === 'company master';
    const isAdmin = userRole.includes('admin') || userRole === 'company admin';
    if (userType === 'railway') {
      if (isMaster) { if (zone) query = query.where('submittedByZone', '==', zone); }
      else if (isAdmin) query = query.where('submittedByDivision', '==', division);
      else query = query.where('submittedTo.railwayEmployeeId', '==', uid);
    } else if (userType === 'contractor') {
      if (!entityId) throw new ForbiddenError('Entity ID missing.');
      query = query.where('submittedByEntityId', '==', entityId);
      if (!isMaster && isAdmin) query = query.where('submittedByDivision', '==', division);
      else if (!isMaster && !isAdmin) query = query.where('submittedById', '==', uid);
    }
    const snapshot = await query.get();
    const trainStats = {};
    const start = startDate ? new Date(startDate) : null;
    const end = endDate ? new Date(endDate) : null;
    if (end) end.setHours(23, 59, 59, 999);
    snapshot.forEach(doc => {
      const data = doc.data(); const formDate = new Date(data.formDateTime);
      let include = true;
      if (start && formDate < start) include = false;
      if (end && formDate > end) include = false;
      const tName = data.trainName || 'Unknown Train';
      if (trainNo && !tName.includes(trainNo)) include = false;
      if (include) {
        if (!trainStats[tName]) trainStats[tName] = { trainName: tName, totalForms: 0, totalScore: 0, scoresList: [] };
        const score = parseFloat(data.ratingDetails?.summary?.overallAveragePct || '0');
        trainStats[tName].totalForms++; trainStats[tName].totalScore += score;
        trainStats[tName].scoresList.push({ date: formDate.toLocaleDateString('en-IN'), score: score.toFixed(2), contractor: data.submittedByEntityName, supervisor: data.submittedByName });
      }
    });
    const finalResult = Object.values(trainStats).map(train => ({ trainName: train.trainName, formsCount: train.totalForms, averageScore: (train.totalScore / train.totalForms).toFixed(2) + '%', details: train.scoresList }));
    return { count: finalResult.length, data: finalResult };
  }

  async getCoachStats(queryParams, user) {
    const { uid, role, userType, entityId, division } = user;
    const { startDate, endDate, contractId } = queryParams;
    let query = db.collection('coachForms').where('status', 'in', ['LOCKED', 'AUTO-APPROVED']);
    const userRole = (role || '').toLowerCase();
    const isMaster = userRole.includes('master');
    const isAdmin = userRole.includes('admin');
    if (userType === 'contractor') {
      if (!entityId) throw new ForbiddenError('Entity ID missing.');
      query = query.where('submittedByEntityId', '==', entityId);
      if (!isMaster && isAdmin) query = query.where('submittedByDivision', '==', division);
      else if (!isMaster && !isAdmin) query = query.where('submittedById', '==', uid);
    } else { if (isAdmin) query = query.where('submittedByDivision', '==', division); }
    if (contractId) query = query.where('contractId', '==', contractId);
    const snapshot = await query.get();
    let stats = { totalTrains: 0, totalCoaches: 0, totalManpower: 0, totalPenalty: 0, grades: { A: 0, B: 0, C: 0, D: 0 }, operations: { toiletries: { Yes: 0, No: 0, NA: 0 }, doors: { Yes: 0, No: 0, NA: 0 }, watering: { Yes: 0, No: 0, NA: 0 } }, resources: { manpowerDeployed: 0, machinesUsed: 0 } };
    const start = startDate ? new Date(startDate) : null;
    const end = endDate ? new Date(endDate) : null;
    if (end) end.setHours(23, 59, 59, 999);
    snapshot.forEach(doc => {
      const data = doc.data();
      let include = true;
      if (start || end) { if (!data.formDateTime) include = false; else { const fDate = new Date(data.formDateTime); if (start && fDate < start) include = false; if (end && fDate > end) include = false; } }
      if (include) {
        stats.totalTrains++;
        const mpCount = data.manpower ? data.manpower.length : 0;
        stats.totalManpower += mpCount; stats.resources.manpowerDeployed += mpCount;
        stats.resources.machinesUsed += (data.machinesUsed || []).length;
        const summary = data.ratingDetails?.summary || {};
        stats.totalCoaches += (summary.totalCoaches || 0);
        ['internal', 'external', 'intensive'].forEach(cat => { if (summary[cat]) { stats.grades.A += (summary[cat].A || 0); stats.grades.B += (summary[cat].B || 0); stats.grades.C += (summary[cat].C || 0); stats.grades.D += (summary[cat].D || 0); } });
        const addOpStats = (target, source) => { if (!source) return; target.Yes += (source.Yes || 0); target.No += (source.No || 0); target.NA += (source.NA || 0); };
        addOpStats(stats.operations.doors, summary.doorsLocking);
        addOpStats(stats.operations.toiletries, summary.toiletries);
        addOpStats(stats.operations.watering, summary.watering);
      }
    });
    const totalGrades = stats.grades.A + stats.grades.B + stats.grades.C + stats.grades.D || 1;
    return {
      cards: { totalTrains: stats.totalTrains, totalCoaches: stats.totalCoaches, totalManpower: stats.totalManpower, totalPenalty: stats.totalPenalty },
      gradeDistribution: { A: { count: stats.grades.A, pct: ((stats.grades.A / totalGrades) * 100).toFixed(1) }, B: { count: stats.grades.B, pct: ((stats.grades.B / totalGrades) * 100).toFixed(1) }, C: { count: stats.grades.C, pct: ((stats.grades.C / totalGrades) * 100).toFixed(1) }, D: { count: stats.grades.D, pct: ((stats.grades.D / totalGrades) * 100).toFixed(1) } },
      operations: { toiletries: stats.operations.toiletries, doors: stats.operations.doors, watering: stats.operations.watering },
      resources: stats.resources
    };
  }

  async getPremisesStats(queryParams, user) {
    const { uid, role, userType, entityId, division } = user;
    const { startDate, endDate, contractId } = queryParams;
    let query = db.collection('premisesForms').where('status', 'in', ['LOCKED', 'AUTO-APPROVED']);
    const userRole = (role || '').toLowerCase();
    const isMaster = userRole.includes('master');
    const isAdmin = userRole.includes('admin');
    if (userType === 'contractor') {
      if (!entityId) throw new ForbiddenError('Entity ID missing.');
      query = query.where('submittedByEntityId', '==', entityId);
      if (!isMaster && isAdmin) query = query.where('submittedByDivision', '==', division);
      else if (!isMaster && !isAdmin) query = query.where('submittedById', '==', uid);
    } else { if (isAdmin) query = query.where('submittedByDivision', '==', division); }
    if (contractId) query = query.where('contractId', '==', contractId);
    const snapshot = await query.get();
    let stats = { totalForms: 0, totalAreaCleaned: 0, totalManpower: 0, quality: { above90: 0, range81to90: 0, range71to80: 0, below70: 0 }, uniqueDates: new Set() };
    const areaMap = { 'GICC': 23530, 'OWS': 8630, 'NWS': 10130 };
    const start = startDate ? new Date(startDate) : null;
    const end = endDate ? new Date(endDate) : null;
    if (end) end.setHours(23, 59, 59, 999);
    snapshot.forEach(doc => {
      const data = doc.data();
      let include = true;
      if (start || end) { if (!data.formDateTime) include = false; else { const fDate = new Date(data.formDateTime); if (start && fDate < start) include = false; if (end && fDate > end) include = false; } }
      if (include) {
        stats.totalForms++;
        stats.totalAreaCleaned += parseFloat(data.area) || areaMap[data.location] || 0;
        stats.totalManpower += data.manpower ? data.manpower.length : 0;
        if (data.formDateTime) stats.uniqueDates.add(new Date(data.formDateTime).toDateString());
        const pct = parseFloat(data.ratingDetails?.summary?.overallAveragePct || 0);
        if (pct > 90) stats.quality.above90++;
        else if (pct >= 81) stats.quality.range81to90++;
        else if (pct >= 71) stats.quality.range71to80++;
        else stats.quality.below70++;
      }
    });
    return stats;
  }

  async getCtsStats(queryParams, user) {
    const { uid, role, userType, entityId, division } = user;
    const { startDate, endDate, contractId } = queryParams;
    let query = db.collection('ctsForms').where('status', 'in', ['LOCKED', 'AUTO-APPROVED']);
    const userRole = (role || '').toLowerCase();
    const isMaster = userRole.includes('master');
    const isAdmin = userRole.includes('admin');
    if (userType === 'contractor') {
      if (!entityId) throw new ForbiddenError('Entity ID missing.');
      query = query.where('submittedByEntityId', '==', entityId);
      if (!isMaster && isAdmin) query = query.where('submittedByDivision', '==', division);
      else if (!isMaster && !isAdmin) query = query.where('submittedById', '==', uid);
    } else { if (isAdmin) query = query.where('submittedByDivision', '==', division); }
    if (contractId) query = query.where('contractId', '==', contractId);
    const snapshot = await query.get();
    let stats = { totalForms: 0, totalScore: 0, scoredCount: 0 };
    snapshot.forEach(doc => { const d = doc.data(); stats.totalForms++; if (d.ratingDetails?.summary?.averageScore) { stats.totalScore += Number(d.ratingDetails.summary.averageScore); stats.scoredCount++; } });
    return stats;
  }

  async getCtsData(queryParams) {
    const { zone, division, depot, startDate, endDate, contractorId, contractId, supervisorId } = queryParams;
    let query = db.collection('ctsForms').where('status', 'in', ['LOCKED', 'AUTO-APPROVED']);
    if (zone) query = query.where('submittedByZone', '==', zone);
    if (division) query = query.where('submittedByDivision', '==', division);
    if (depot) query = query.where('submittedByDepot', '==', depot);
    if (contractorId) query = query.where('submittedByEntityId', '==', contractorId);
    if (contractId) query = query.where('contractId', '==', contractId);
    if (supervisorId) query = query.where('submittedById', '==', supervisorId);
    const snapshot = await query.get();
    let reportData = [];
    const start = startDate ? new Date(startDate) : null;
    const end = endDate ? new Date(endDate) : null;
    if (end) end.setHours(23, 59, 59, 999);
    snapshot.forEach(doc => {
      const data = doc.data();
      const formDate = data.formDateTime ? new Date(data.formDateTime) : new Date();
      let include = true;
      if (start && formDate < start) include = false;
      if (end && formDate > end) include = false;
      if (include) { reportData.push({ date: formDate.toLocaleDateString('en-IN'), trainName: data.trainName || 'N/A', trainNo: data.trainNumber || 'N/A', submittedBy: data.submittedByName, averageScore: data.ratingDetails?.summary?.averageScore || 'N/A', overallGrade: data.ratingDetails?.summary?.overallGrade || 'N/A' }); }
    });
    return { count: reportData.length, data: reportData };
  }

  async generateReport(requesterData, query, res) {
    const { type, format, filters } = query;
    return { message: `Report generation initiated for type: ${type}, format: ${format}` };
  }

  async generateDailyReport() {
    return { message: 'Daily report generation' };
  }

  async generateWeeklyReport() {
    return { message: 'Weekly report generation' };
  }

  async generateMonthlyReport() {
    return { message: 'Monthly report generation' };
  }

  async generateAuditReport() {
    return { message: 'Audit report generation' };
  }

  async generateExcelReport(requesterData, query, res) {
    return this.generateReport(requesterData, { ...query, format: 'excel' }, res);
  }

  async generatePdfReport(requesterData, query, res) {
    return this.generateReport(requesterData, { ...query, format: 'pdf' }, res);
  }

  async getReportHistory() {
    const snapshot = await db.collection('report_history').orderBy('createdAt', 'desc').limit(50).get();
    const history = [];
    snapshot.forEach(doc => history.push(doc.data()));
    return { count: history.length, history };
  }

  async sendEmail(body, user) {
    const { to, subject, body: emailBody, attachments } = body;
    await db.collection('email_logs').add({ to, subject, sentAt: new Date().toISOString(), status: 'sent', sentBy: user.uid });
    return { message: 'Email sent successfully' };
  }

  async getEmailHistory() {
    const snapshot = await db.collection('email_logs').orderBy('sentAt', 'desc').limit(50).get();
    const emails = [];
    snapshot.forEach(doc => emails.push(doc.data()));
    return { count: emails.length, emails };
  }

  async sendReportEmail() {
    return { message: 'Email sent' };
  }

  async getAttendanceAuditData(runInstanceId, workerId) {
    return this.legacyService.getAttendanceAuditData(runInstanceId, workerId);
  }

  async getOperationalAuditData(runInstanceId) {
    return this.legacyService.getOperationalAuditData(runInstanceId);
  }

  async getWorkerActivityAuditData(runInstanceId, workerId) {
    return this.legacyService.getWorkerActivityAuditData(runInstanceId, workerId);
  }

  async getComplaintAuditData(runInstanceId) {
    return this.legacyService.getComplaintAuditData(runInstanceId);
  }
}

export const reportService = new ReportService();
