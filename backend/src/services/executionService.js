import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

class ExecutionService {
  async createPlan(userData, body) {
    const { contractId, stationId, month, year, manpowerPlan } = body;
    if (!contractId || !stationId || !month || !year) throw new ValidationError('contractId, stationId, month, and year are required');

    const ref = db.collection('execution_plans').doc();
    const data = {
      uid: ref.id, contractId, stationId, month, year,
      status: 'DRAFT',
      manpowerPlan: manpowerPlan || {},
      machinePlan: body.machinePlan || {},
      materialPlan: body.materialPlan || [],
      garbageDisposalPlan: body.garbageDisposalPlan || {},
      createdBy: userData.uid, createdByName: userData.fullName || '',
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Execution plan created', uid: ref.id, plan: data };
  }

  async getPlans(query = {}) {
    const { contractId, stationId, status, limit = 50, cursor } = query;
    let q = db.collection('execution_plans');
    if (contractId) q = q.where('contractId', '==', contractId);
    if (stationId) q = q.where('stationId', '==', stationId);
    if (status) q = q.where('status', '==', status);
    const result = await paginate(q, { limit, cursor, orderBy: 'createdAt', orderDir: 'desc' });
    return { count: result.items.length, plans: result.items, pagination: result.pagination };
  }

  async getPlanById(uid) {
    const doc = await db.collection('execution_plans').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Execution plan not found');
    return { id: doc.id, ...doc.data() };
  }

  async updatePlan(uid, body) {
    const ref = db.collection('execution_plans').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Execution plan not found');
    const allowed = ['manpowerPlan', 'machinePlan', 'materialPlan', 'garbageDisposalPlan'];
    const updates = {};
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }
    updates.updatedAt = new Date().toISOString();
    await ref.update(updates);
    return { message: 'Execution plan updated', uid };
  }

  async submitPlan(uid, userData) {
    const ref = db.collection('execution_plans').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Execution plan not found');
    if (doc.data().status !== 'DRAFT' && doc.data().status !== 'REJECTED') throw new ValidationError('Only DRAFT or REJECTED plans can be submitted');
    await ref.update({ status: 'SUBMITTED', submittedBy: userData.uid, submittedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Execution plan submitted for approval', uid };
  }

  async approvePlan(uid, userData) {
    const ref = db.collection('execution_plans').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Execution plan not found');
    if (doc.data().status !== 'SUBMITTED') throw new ValidationError('Only SUBMITTED plans can be approved');
    await ref.update({ status: 'APPROVED', approvedBy: userData.uid, approvedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Execution plan approved', uid };
  }

  async rejectPlan(uid, userData, body) {
    const ref = db.collection('execution_plans').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Execution plan not found');
    if (doc.data().status !== 'SUBMITTED') throw new ValidationError('Only SUBMITTED plans can be rejected');
    await ref.update({ status: 'REJECTED', rejectionReason: body.reason || '', rejectedBy: userData.uid, rejectedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Execution plan rejected', uid };
  }

  async deletePlan(uid) {
    const ref = db.collection('execution_plans').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Execution plan not found');
    await ref.delete();
    return { message: 'Execution plan deleted' };
  }

  async createDailyLog(userData, body) {
    const { stationId, date, shift, actualManpower, plannedManpower } = body;
    if (!stationId || !date || !shift) throw new ValidationError('stationId, date, and shift are required');

    const ref = db.collection('execution_logs').doc();
    const variance = (actualManpower || 0) - (plannedManpower || 0);
    const data = {
      uid: ref.id, stationId, date, shift,
      actualManpower: actualManpower || 0,
      plannedManpower: plannedManpower || 0,
      variance,
      reasonForVariance: body.reasonForVariance || '',
      machinesDeployed: body.machinesDeployed || {},
      garbageDisposal: body.garbageDisposal || {},
      issuesEncountered: body.issuesEncountered || [],
      unresolvedWork: body.unresolvedWork || [],
      handoverNotes: body.handoverNotes || '',
      createdBy: userData.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Daily execution log created', uid: ref.id, log: data };
  }

  async getDailyLogs(query = {}) {
    const { stationId, date, shift, limit = 50, cursor } = query;
    let q = db.collection('execution_logs');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (date) q = q.where('date', '==', date);
    if (shift) q = q.where('shift', '==', shift);
    const result = await paginate(q, { limit, cursor, orderBy: 'createdAt', orderDir: 'desc' });
    return { count: result.items.length, logs: result.items, pagination: result.pagination };
  }

  async getDailyLogById(uid) {
    const doc = await db.collection('execution_logs').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Execution log not found');
    return { id: doc.id, ...doc.data() };
  }
}

export const executionService = new ExecutionService();
