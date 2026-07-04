/*
 * Required Firestore composite indexes (create in Firebase Console before deploying):
 *  1. Collection `daily_scorecards` – fields: `stationId` ASC, `date` ASC
 *  2. Collection `station_attendance` – fields: `stationId` ASC, `date` ASC
 *  3. Collection `station_feedback` – fields: `stationId` ASC, `createdAt` ASC
 *  4. Collection `complaints` – fields: `stationId` ASC, `createdAt` ASC
 *  5. Collection `station_daily_activities` – fields: `stationId` ASC, `date` ASC
 *  6. Collection `execution_logs` – fields: `stationId` ASC, `date` ASC
 *  7. Collection `email_history` – fields: `stationId` ASC, `sentAt` ASC
 */

import { db, admin } from '../database/index.js';
import { ValidationError } from '../errors/index.js';
import config from '../config/index.js';

const CACHE_TTL = 300;
const cache = {};

class DashboardService {
  _cacheKey(prefix, params) {
    return prefix + '_' + JSON.stringify(params);
  }
  _getCached(key) {
    const entry = cache[key];
    if (entry && Date.now() - entry.ts < CACHE_TTL * 1000) return entry.data;
    return null;
  }
  _setCache(key, data) {
    cache[key] = { data, ts: Date.now() };
    if (Object.keys(cache).length > 200) {
      const oldest = Object.entries(cache).sort((a, b) => a[1].ts - b[1].ts)[0][0];
      delete cache[oldest];
    }
  }

  async getDashboardStats(requesterData) {
    const { role, userType, zone: userZone, division: userDiv } = requesterData;
    const cacheKey = this._cacheKey('stats', { role, userZone, userDiv });
    const cached = this._getCached(cacheKey);
    if (cached) return cached;

    const [userSnap, entitySnap, trainSnap, contractSnap] = await Promise.all([
      db.collection('users').get(),
      db.collection('entities').get(),
      db.collection('trains').get(),
      db.collection('contracts').get()
    ]);

    const userRole = (role || '').trim().toLowerCase();
    const isSuperAdmin = userRole.includes('super admin');
    const isMaster = userRole.includes('master');
    const isAdmin = userRole.includes('admin') || userRole.includes('supervisor');

    const stats = {
      user: { total: 0, approved: 0, pending: 0, railway: 0, contractor: 0 },
      entity: { total: 0, approved: 0, pending: 0 },
      train: { total: 0, active: 0 }
    };

    userSnap.docs.forEach(doc => {
      const d = doc.data();
      let visible = isSuperAdmin || (isMaster && d.zone === userZone) || (isAdmin && d.division === userDiv);
      if (visible) {
        stats.user.total++;
        if (d.status === 'APPROVED') stats.user.approved++;
        else if (d.status === 'PENDING') stats.user.pending++;
        if (d.userType === 'railway') stats.user.railway++;
        if (d.userType === 'contractor') stats.user.contractor++;
      }
    });
    entitySnap.docs.forEach(doc => {
      const d = doc.data();
      stats.entity.total++;
      if (d.status === 'APPROVED') stats.entity.approved++;
      if (d.status === 'PENDING') stats.entity.pending++;
    });
    trainSnap.docs.forEach(doc => {
      const d = doc.data();
      let visible = isSuperAdmin || (isMaster && d.zone === userZone) || (isAdmin && d.division === userDiv);
      if (visible) { stats.train.total++; if (d.status === 'ACTIVE' || d.status === 'active') stats.train.active++; }
    });

    const result = {
      systemOverview: {
        railwayEmployees: stats.user.railway, contractorEmployees: stats.user.contractor,
        totalRegisteredEntities: stats.entity.total,
        activeContracts: contractSnap.docs.filter(c => c.data().status === 'ACTIVE').length,
        totalFormsProcessed: 0
      },
      userOverview: stats.user, entityOverview: stats.entity, trainOverview: stats.train
    };
    this._setCache(cacheKey, result);
    return result;
  }

  async getRailwayDashboardStats(requesterData) {
    const { uid: userId, role, division: userDivision, entityId: userEntityId } = requesterData;
    const cacheKey = this._cacheKey('railStats', { role, userDivision, userEntityId });
    const cached = this._getCached(cacheKey);
    if (cached) return cached;

    const [divisionsSnap, depotsSnap, usersSnap, companiesSnap, contractsSnap, formsSnap] = await Promise.all([
      db.collection('divisions').get(), db.collection('depots').get(),
      db.collection('users').get(), db.collection('companies').get(),
      db.collection('contracts').get(), db.collection('forms_processed').get()
    ]);
    const allUsers = usersSnap.docs.map(d => ({ id: d.id, ...d.data() }));
    const allContracts = contractsSnap.docs.map(d => ({ id: d.id, ...d.data() }));
    const allDepots = depotsSnap.docs.map(d => ({ id: d.id, ...d.data() }));

    let stats = { divisions: 0, depots: 0, railwayEmployees: 0, contractorEmployees: 0,
      registeredEntities: 0, activeContracts: 0, totalFormProcessed: formsSnap.size };
    const nr = (role || '').toLowerCase();

    if (nr === 'admin' || nr === 'super_admin') {
      stats.divisions = divisionsSnap.size;
      stats.depots = depotsSnap.size;
      stats.registeredEntities = companiesSnap.size;
      stats.railwayEmployees = allUsers.filter(u => u.userType === 'railway' || (u.role || '').toLowerCase().includes('railway')).length;
      stats.contractorEmployees = allUsers.filter(u => u.userType === 'contractor').length;
      stats.activeContracts = allContracts.filter(c => c.status === 'Active' || c.status === 'active').length;
    } else if (nr.includes('railway') || nr.includes('supervisor')) {
      stats.divisions = userDivision ? 1 : 0;
      stats.depots = allDepots.filter(d => d.division === userDivision).length;
      stats.railwayEmployees = allUsers.filter(u => u.division === userDivision && (u.userType === 'railway' || (u.role || '').toLowerCase().includes('railway'))).length;
      stats.contractorEmployees = allUsers.filter(u => u.division === userDivision && u.userType === 'contractor').length;
      stats.activeContracts = allContracts.filter(c => c.division === userDivision && (c.status === 'Active' || c.status === 'active')).length;
      stats.totalFormProcessed = formsSnap.docs.filter(f => f.data().division === userDivision).length;
    } else if (nr.includes('company')) {
      stats.registeredEntities = 1;
      stats.contractorEmployees = allUsers.filter(u => u.entityId === userEntityId).length;
      stats.activeContracts = allContracts.filter(c => c.entityId === userEntityId && (c.status === 'Active' || c.status === 'active')).length;
      const myContracts = allContracts.filter(c => c.entityId === userEntityId);
      stats.divisions = [...new Set(myContracts.map(c => c.division))].length;
      stats.depots = [...new Set(myContracts.map(c => c.depot))].length;
    }

    const result = { success: true, data: stats };
    this._setCache(cacheKey, result);
    return result;
  }

  async getStationDashboard(stationId, query = {}) {
    if (!stationId) throw new ValidationError('stationId is required');
    const { startDate, endDate, month, year } = query;
    let sDate, eDate;
    if (month && year) {
      const m = String(month).padStart(2, '0');
      sDate = `${year}-${m}-01`; eDate = `${year}-${m}-31`;
    } else {
      sDate = startDate || new Date(Date.now() - 30 * 86400000).toISOString().split('T')[0];
      eDate = endDate || new Date().toISOString().split('T')[0];
    }

    const cacheKey = this._cacheKey('stnDash', { stationId, sDate, eDate });
    const cached = this._getCached(cacheKey);
    if (cached) return cached;

    const [scoreSnap, attendSnap, feedbackSnap, complaintSnap, machineSnap, actSnap, logSnap, freqSnap, billingSnap, emailSnap] = await Promise.all([
      db.collection('daily_scorecards').where('stationId', '==', stationId).where('date', '>=', sDate).where('date', '<=', eDate).get(),
      db.collection('station_attendance').where('stationId', '==', stationId).where('date', '>=', sDate).where('date', '<=', eDate).get(),
      db.collection('station_feedback').where('stationId', '==', stationId).where('createdAt', '>=', sDate).where('createdAt', '<=', eDate + 'T23:59:59').get(),
      db.collection('complaints').where('stationId', '==', stationId).where('createdAt', '>=', sDate).where('createdAt', '<=', eDate + 'T23:59:59').get(),
      db.collection('machines').where('stationId', '==', stationId).get(),
      db.collection('station_daily_activities').where('stationId', '==', stationId).where('date', '>=', sDate).where('date', '<=', eDate).get(),
      db.collection('execution_logs').where('stationId', '==', stationId).where('date', '>=', sDate).where('date', '<=', eDate).get(),
      db.collection('activity_frequencies').where('stationId', '==', stationId).get(),
      db.collection('station_billing_packs').where('stationId', '==', stationId).get(),
      db.collection('email_history').where('stationId', '==', stationId).get(),
    ]);

    const scores = []; scoreSnap.forEach(d => scores.push(d.data()));
    const avgScore = scores.length > 0 ? Math.round(scores.reduce((s, c) => s + (c.overallStationScore || 0), 0) / scores.length) : 0;
    const scoreTrend = scores.sort((a, b) => a.date.localeCompare(b.date)).map(c => ({ date: c.date, score: c.overallStationScore, grade: c.grade }));

    const attendance = []; attendSnap.forEach(d => attendance.push(d.data()));
    const present = attendance.filter(r => r.status === 'present' || r.status === 'late').length;
    const absent = attendance.filter(r => r.status === 'absent').length;

    const feedbacks = []; feedbackSnap.forEach(d => feedbacks.push(d.data()));
    const avgFeedback = feedbacks.length > 0 ? Math.round(feedbacks.reduce((s, f) => s + (f.rating || 0), 0) / feedbacks.length * 10) / 10 : 0;

    const complaints = []; complaintSnap.forEach(d => complaints.push(d.data()));
    const openComplaints = complaints.filter(c => !['CLOSED', 'RAILWAY_VERIFIED', 'REJECTED'].includes(c.status)).length;

    const machines = []; machineSnap.forEach(d => machines.push(d.data()));
    const inMaintenance = machines.filter(m => m.workingStatus === 'under_maintenance' || m.workingStatus === 'broken').length;

    const activities = []; actSnap.forEach(d => activities.push(d.data()));
    const completedActs = activities.filter(a => a.status === 'COMPLETED' || a.status === 'APPROVED').length;

    const execLogs = []; logSnap.forEach(d => execLogs.push(d.data()));
    const plannedManpower = execLogs.reduce((s, l) => s + (l.plannedManpower || 0), 0);
    const actualManpower = execLogs.reduce((s, l) => s + (l.actualManpower || 0), 0);

    const frequencies = []; freqSnap.forEach(d => frequencies.push(d.data()));
    const missedAlerts = frequencies.filter(f => {
      if (!f.frequency || !f.lastCompletedDate) return false;
      const last = new Date(f.lastCompletedDate);
      const now = new Date();
      const daysSinceLast = (now - last) / 86400000;
      if (f.frequency === 'daily' && daysSinceLast > 1.5) return true;
      if (f.frequency === 'weekly' && daysSinceLast > 8) return true;
      if (f.frequency === 'monthly' && daysSinceLast > 32) return true;
      return false;
    }).length;

    const billingPacks = []; billingSnap.forEach(d => billingPacks.push(d.data()));
    const billingReady = billingPacks.filter(b => b.status === 'SUBMITTED' || b.status === 'APPROVED').length;
    const billingDraft = billingPacks.filter(b => b.status === 'DRAFT').length;

    const emailLogs = []; emailSnap.forEach(d => emailLogs.push(d.data()));
    const reportsSent = emailLogs.length;

    const result = {
      stationId, period: { start: sDate, end: eDate },
      scorecard: { daysWithScore: scores.length, averageScore: avgScore, trend: scoreTrend },
      attendance: { total: attendance.length, present, absent, attendanceRate: attendance.length > 0 ? Math.round(present / attendance.length * 100) : 0 },
      feedback: { total: feedbacks.length, averageRating: avgFeedback, negative: feedbacks.filter(f => f.isNegative).length },
      complaints: { total: complaints.length, open: openComplaints, closed: complaints.filter(c => c.status === 'CLOSED').length },
      machines: { total: machines.length, inMaintenance, operational: machines.length - inMaintenance },
      activities: { total: activities.length, completed: completedActs, completionRate: activities.length > 0 ? Math.round(completedActs / activities.length * 100) : 0 },
      plannedVsCompleted: { planned: plannedManpower, actual: actualManpower, variance: plannedManpower - actualManpower },
      missedAlerts: { count: missedAlerts, alert: missedAlerts > 0 },
      billingReadiness: { total: billingPacks.length, ready: billingReady, draft: billingDraft },
      reportsSent: { count: reportsSent }
    };
    this._setCache(cacheKey, result);
    return result;
  }

  async getUserStats() {
    const snapshot = await db.collection('users').get();
    const users = snapshot.docs.map(d => d.data());
    return { total: users.length, approved: users.filter(u => u.status === 'APPROVED').length,
      pending: users.filter(u => u.status === 'PENDING').length,
      railway: users.filter(u => u.userType === 'railway').length,
      contractor: users.filter(u => u.userType === 'contractor').length };
  }

  async getTrainStats() {
    const snapshot = await db.collection('trains').get();
    const trains = snapshot.docs.map(d => d.data());
    return { total: trains.length, active: trains.filter(t => t.status === 'ACTIVE' || t.status === 'active').length,
      obhsEnabled: trains.filter(t => (t.TrainApplicableFor || []).includes('OBHS')).length,
      ctsEnabled: trains.filter(t => (t.TrainApplicableFor || []).includes('CTS')).length };
  }

  async getSupervisorStats(requesterData) {
    const { division } = requesterData;
    const [usersSnap, formsSnap, tasksSnap] = await Promise.all([
      db.collection('users').where('division', '==', division).get(),
      db.collection('coachForms').where('division', '==', division).get(),
      db.collection('obhs_tasks').where('division', '==', division).get()
    ]);
    const users = usersSnap.docs.map(d => d.data());
    const forms = formsSnap.docs.map(d => d.data());
    const tasks = tasksSnap.docs.map(d => d.data());
    return { totalWorkers: users.filter(u => u.userType === 'contractor').length,
      activeForms: forms.filter(f => f.status === 'SUBMITTED' || f.status === 'APPROVED').length,
      pendingReview: tasks.filter(t => t.status === 'PENDING_REVIEW').length,
      completedToday: tasks.filter(t => t.status === 'COMPLETED').length };
  }

  async getActiveTrains() {
    const snapshot = await db.collection('trains').where('status', '==', 'active').get();
    return { count: snapshot.size, trains: snapshot.docs.map(d => ({ uid: d.id, ...d.data() })) };
  }

  async getActiveWorkers() {
    const snapshot = await db.collection('users').where('userType', '==', 'contractor').where('status', '==', 'APPROVED').get();
    return { count: snapshot.size, workers: snapshot.docs.map(d => ({ id: d.id, ...d.data() })) };
  }

  async getAllFormsStats() {
    const [coachSnap, premisesSnap, ctsSnap, cleaningSnap] = await Promise.all([
      db.collection('coachForms').get(), db.collection('premisesForms').get(),
      db.collection('ctsForms').get(), db.collection('cleaningForms').get()
    ]);
    return { coachForms: coachSnap.size, premisesForms: premisesSnap.size,
      ctsForms: ctsSnap.size, cleaningForms: cleaningSnap.size,
      total: coachSnap.size + premisesSnap.size + ctsSnap.size + cleaningSnap.size };
  }
}

export const dashboardService = new DashboardService();
