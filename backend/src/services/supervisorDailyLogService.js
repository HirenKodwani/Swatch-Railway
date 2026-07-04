import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

const VALID_STATUSES = ['DRAFT', 'SUBMITTED', 'ACKNOWLEDGED', 'ACCEPTED', 'RETURNED', 'REJECTED'];

class SupervisorDailyLogService {
  async createLog(userData, body) {
    const { stationId, date, shift } = body;
    if (!stationId || !date || !shift) throw new ValidationError('stationId, date, and shift are required');
    if (!['MORNING', 'EVENING', 'NIGHT'].includes(shift)) throw new ValidationError('Invalid shift. Use MORNING, EVENING, or NIGHT');

    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');

    const ref = db.collection('supervisor_daily_logs').doc();
    const data = {
      uid: ref.id, stationId, stationName: stationDoc.data().stationName || '',
      date, shift, status: 'DRAFT', activities: body.activities || [],
      workerAttendance: body.workerAttendance || [],
      materialUsage: body.materialUsage || [],
      issues: body.issues || [], photos: body.photos || [],
      supervisorName: userData.fullName || userData.name || '',
      supervisorId: userData.uid,
      remarks: body.remarks || '',
      submittedAt: null, submittedBy: null,
      acknowledgedAt: null, acknowledgedBy: null,
      acceptedAt: null, acceptedBy: null,
      rejectedAt: null, rejectedBy: null, rejectionReason: null,
      returnedAt: null, returnedBy: null, returnReason: null,
      acknowledgeRemark: body.acknowledgeRemark || '',
      createdBy: userData.uid, createdByName: userData.fullName || userData.name || '',
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Supervisor log created', uid: ref.id, log: data };
  }

  async submitLog(uid, userData) {
    const ref = db.collection('supervisor_daily_logs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Log not found');
    if (doc.data().status !== 'DRAFT') throw new ValidationError('Only DRAFT logs can be submitted');
    await ref.update({ status: 'SUBMITTED', submittedBy: userData.uid, submittedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Log submitted for acknowledgment' };
  }

  async acknowledgeLog(uid, userData) {
    const ref = db.collection('supervisor_daily_logs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Log not found');
    if (doc.data().status !== 'SUBMITTED') throw new ValidationError('Only SUBMITTED logs can be acknowledged');
    await ref.update({ status: 'ACKNOWLEDGED', acknowledgedBy: userData.uid, acknowledgedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Log acknowledged' };
  }

  async acceptLog(uid, userData) {
    const ref = db.collection('supervisor_daily_logs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Log not found');
    if (!['ACKNOWLEDGED', 'SUBMITTED'].includes(doc.data().status)) throw new ValidationError('Log must be acknowledged first');
    await ref.update({ status: 'ACCEPTED', acceptedBy: userData.uid, acceptedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Log accepted' };
  }

  async rejectLog(uid, userData, body) {
    const ref = db.collection('supervisor_daily_logs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Log not found');
    if (!['SUBMITTED', 'ACKNOWLEDGED'].includes(doc.data().status)) throw new ValidationError('Only SUBMITTED or ACKNOWLEDGED logs can be rejected');
    if (!body.reason) throw new ValidationError('Rejection reason is required');
    await ref.update({ status: 'REJECTED', rejectedBy: userData.uid, rejectedAt: new Date().toISOString(), rejectionReason: body.reason, updatedAt: new Date().toISOString() });
    return { message: 'Log rejected' };
  }

  async returnLog(uid, userData, body) {
    const ref = db.collection('supervisor_daily_logs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Log not found');
    if (!['SUBMITTED', 'ACKNOWLEDGED'].includes(doc.data().status)) throw new ValidationError('Only SUBMITTED or ACKNOWLEDGED logs can be returned');
    if (!body.reason) throw new ValidationError('Return reason is required');
    await ref.update({ status: 'RETURNED', returnedBy: userData.uid, returnedAt: new Date().toISOString(), returnReason: body.reason, updatedAt: new Date().toISOString() });
    return { message: 'Log returned for revision' };
  }

  async updateLog(uid, userData, body) {
    const ref = db.collection('supervisor_daily_logs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Log not found');
    if (!['DRAFT', 'RETURNED'].includes(doc.data().status)) throw new ValidationError('Only DRAFT or RETURNED logs can be edited');
    const allowed = ['activities', 'workerAttendance', 'materialUsage', 'issues', 'photos', 'remarks'];
    const updates = {};
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }
    updates.updatedAt = new Date().toISOString();
    await ref.update(updates);
    return { message: 'Log updated', uid };
  }

  async getLogById(uid) {
    const doc = await db.collection('supervisor_daily_logs').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Log not found');
    return { id: doc.id, ...doc.data() };
  }

  async listLogs(query = {}) {
    const { stationId, date, startDate, endDate, shift, status, supervisorId, limit = 50, cursor } = query;
    let q = db.collection('supervisor_daily_logs');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (date) q = q.where('date', '==', date);
    if (shift) q = q.where('shift', '==', shift);
    if (status) q = q.where('status', '==', status);
    if (supervisorId) q = q.where('supervisorId', '==', supervisorId);
    if (startDate) q = q.where('date', '>=', startDate);
    if (endDate) q = q.where('date', '<=', endDate);
    const result = await paginate(q, { limit, cursor, orderBy: 'date', orderDir: 'desc' });
    return { count: result.items.length, logs: result.items, pagination: result.pagination };
  }

  async getShiftHandover(stationId, date, shift) {
    if (!stationId || !date || !shift) throw new ValidationError('stationId, date, and shift are required');
    const logs = await this.listLogs({ stationId, date, shift });
    const log = logs.logs[0];
    if (!log) return { message: 'No log found for this shift', handover: null };
    return log;
  }
}

export const supervisorDailyLogService = new SupervisorDailyLogService();
