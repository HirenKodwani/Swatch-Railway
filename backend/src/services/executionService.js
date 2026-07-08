/*
 * Required Firestore composite indexes:
 *  1. `execution_plans` – `stationId` ASC, `month` ASC, `year` ASC
 *  2. `execution_logs` – `stationId` ASC, `date` ASC
 *  3. `execution_logs` – `stationId` ASC, `date` ASC, `shift` ASC
 */

import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';
import { notificationService } from './notificationService.js';

class ExecutionService {
  async _validateWorkerIds(workerIds) {
    if (!workerIds || workerIds.length === 0) return;
    const invalid = [];
    for (let i = 0; i < workerIds.length; i += 30) {
      const chunk = workerIds.slice(i, i + 30);
      const snap = await db.collection('users').where('uid', 'in', chunk).where('userType', '==', 'contractor').where('active', '==', true).get();
      const found = new Set();
      snap.forEach(d => found.add(d.data().uid || d.id));
      for (const id of chunk) if (!found.has(id)) invalid.push(id);
    }
    if (invalid.length > 0) throw new ValidationError(`Invalid or inactive worker IDs: ${invalid.join(', ')}`);
  }

  async _checkShiftConflicts(shiftPlan) {
    if (!shiftPlan) return;
    const allWorkerIds = [];
    for (const shift of ['morning', 'afternoon', 'night']) {
      allWorkerIds.push(...(shiftPlan[shift] || []));
    }
    const seen = {};
    for (const id of allWorkerIds) {
      if (seen[id]) throw new ValidationError(`Worker ${id} is assigned to multiple shifts`);
      seen[id] = true;
    }
  }

  async _sendNotification(userId, title, message) {
    if (!userId) return;
    try { await notificationService.createNotification(userId, title, message, 'execution_plan', null); }
    catch { /* non-critical */ }
  }

  async createPlan(userData, body) {
    const { contractId, stationId, month, year, manpowerPlan, shiftPlan } = body;
    if (!contractId || !stationId || !month || !year) throw new ValidationError('contractId, stationId, month, and year are required');
    if (shiftPlan) {
      const allWorkers = [];
      for (const s of ['morning', 'afternoon', 'night']) allWorkers.push(...(shiftPlan[s] || []));
      if (allWorkers.length > 0) await this._validateWorkerIds([...new Set(allWorkers)]);
      await this._checkShiftConflicts(shiftPlan);
    }
    const ref = db.collection('execution_plans').doc();
    const allWorkerIds = [];
    for (const s of ['morning', 'afternoon', 'night']) allWorkerIds.push(...((shiftPlan || {})[s] || []));
    const data = {
      uid: ref.id, contractId, stationId, month, year, status: 'DRAFT', version: 1,
      manpowerPlan: manpowerPlan || {},
      shiftPlan: shiftPlan || { morning: [], afternoon: [], night: [] },
      workerIds: allWorkerIds,
      machinePlan: body.machinePlan || {},
      materialPlan: body.materialPlan || [],
      garbageDisposalPlan: body.garbageDisposalPlan || {},
      weeklySchedule: body.weeklySchedule || [],
      createdBy: userData.uid, createdByName: userData.fullName || '',
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Execution plan created', uid: ref.id, plan: data };
  }

  async getPlans(query = {}) {
    const { contractId, stationId, status, workerId, month, year, limit = 50, cursor } = query;
    let q = db.collection('execution_plans');
    if (contractId) q = q.where('contractId', '==', contractId);
    if (stationId) q = q.where('stationId', '==', stationId);
    if (status) q = q.where('status', '==', status);
    if (workerId) q = q.where('workerIds', 'array-contains', workerId);
    if (month) q = q.where('month', '==', Number(month));
    if (year) q = q.where('year', '==', Number(year));
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
    const allowed = ['manpowerPlan', 'shiftPlan', 'machinePlan', 'materialPlan', 'garbageDisposalPlan', 'weeklySchedule'];
    const updates = {};
    for (const key of allowed) { if (body[key] !== undefined) updates[key] = body[key]; }
    if (body.shiftPlan) {
      const allWorkers = [];
      for (const s of ['morning', 'afternoon', 'night']) allWorkers.push(...(body.shiftPlan[s] || []));
      if (allWorkers.length > 0) await this._validateWorkerIds([...new Set(allWorkers)]);
      await this._checkShiftConflicts(body.shiftPlan);
      updates.workerIds = allWorkers;
    }
    updates.version = (doc.data().version || 0) + 1;
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
    await this._sendNotification(userData.uid, 'Plan Submitted', `Execution plan ${uid} submitted for approval`);
    return { message: 'Execution plan submitted', uid };
  }

  async approvePlan(uid, userData) {
    const ref = db.collection('execution_plans').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Execution plan not found');
    if (doc.data().status !== 'SUBMITTED') throw new ValidationError('Only SUBMITTED plans can be approved');
    await ref.update({ status: 'APPROVED', approvedBy: userData.uid, approvedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    await this._sendNotification(doc.data().createdBy, 'Plan Approved', `Execution plan ${uid} has been approved`);
    return { message: 'Execution plan approved', uid };
  }

  async rejectPlan(uid, userData, body) {
    const ref = db.collection('execution_plans').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Execution plan not found');
    if (doc.data().status !== 'SUBMITTED') throw new ValidationError('Only SUBMITTED plans can be rejected');
    await ref.update({ status: 'REJECTED', rejectionReason: body.reason || '', rejectedBy: userData.uid, rejectedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    await this._sendNotification(doc.data().createdBy, 'Plan Rejected', `Execution plan ${uid} was rejected. Reason: ${body.reason || 'N/A'}`);
    return { message: 'Execution plan rejected', uid };
  }

  async deletePlan(uid) {
    const ref = db.collection('execution_plans').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Execution plan not found');
    await ref.update({ status: 'DELETED', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Execution plan deleted' };
  }

  async createDailyLog(userData, body) {
    const { stationId, date, shift, plannedManpower } = body;
    if (!stationId || !date || !shift) throw new ValidationError('stationId, date, and shift are required');
    const ref = db.collection('execution_logs').doc();
    const actualManpower = body.actualManpower || 0;
    const variance = actualManpower - (plannedManpower || 0);
    const data = {
      uid: ref.id, stationId, date, shift, status: body.status || 'DRAFT',
      actualManpower, plannedManpower: plannedManpower || 0, variance,
      reasonForVariance: body.reasonForVariance || '',
      machinesDeployed: body.machinesDeployed || {},
      materialUsed: body.materialUsed || [],
      garbageCollected: body.garbageCollected || {},
      issuesEncountered: body.issuesEncountered || [],
      unresolvedWork: body.unresolvedWork || [],
      handoverNotes: body.handoverNotes || '',
      submittedBy: null, submittedAt: null,
      approvedBy: null, approvedAt: null,
      createdBy: userData.uid, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Daily execution log created', uid: ref.id, log: data };
  }

  async submitDailyLog(uid, userData) {
    const ref = db.collection('execution_logs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Execution log not found');
    if (doc.data().status !== 'DRAFT') throw new ValidationError('Only DRAFT logs can be submitted');
    await ref.update({ status: 'SUBMITTED', submittedBy: userData.uid, submittedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Daily log submitted' };
  }

  async approveDailyLog(uid, userData) {
    const ref = db.collection('execution_logs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Execution log not found');
    if (doc.data().status !== 'SUBMITTED') throw new ValidationError('Only SUBMITTED logs can be approved');
    await ref.update({ status: 'APPROVED', approvedBy: userData.uid, approvedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Daily log approved' };
  }

  async rejectDailyLog(uid, userData, body) {
    const ref = db.collection('execution_logs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Execution log not found');
    if (doc.data().status !== 'SUBMITTED' && doc.data().status !== 'DRAFT') throw new ValidationError('Only SUBMITTED or DRAFT logs can be rejected');
    await ref.update({ status: 'REJECTED', rejectionReason: body.reason || '', rejectedBy: userData.uid, rejectedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Daily log rejected' };
  }

  async getDailyLogs(query = {}) {
    const { stationId, date, shift, status, limit = 50, cursor } = query;
    let q = db.collection('execution_logs');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (date) q = q.where('date', '==', date);
    if (shift) q = q.where('shift', '==', shift);
    if (status) q = q.where('status', '==', status);
    const result = await paginate(q, { limit, cursor, orderBy: 'createdAt', orderDir: 'desc' });
    return { count: result.items.length, logs: result.items, pagination: result.pagination };
  }

  async getDailyLogById(uid) {
    const doc = await db.collection('execution_logs').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Execution log not found');
    return { id: doc.id, ...doc.data() };
  }

  async updateDailyLog(uid, body) {
    const ref = db.collection('execution_logs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Execution log not found');
    const allowed = ['actualManpower', 'plannedManpower', 'reasonForVariance', 'machinesDeployed', 'materialUsed', 'garbageCollected', 'issuesEncountered', 'unresolvedWork', 'handoverNotes'];
    const updates = { updatedAt: new Date().toISOString() };
    for (const key of allowed) { if (body[key] !== undefined) updates[key] = body[key]; }
    if (body.actualManpower !== undefined || body.plannedManpower !== undefined) {
      const planned = body.plannedManpower !== undefined ? body.plannedManpower : doc.data().plannedManpower;
      updates.variance = (body.actualManpower !== undefined ? body.actualManpower : doc.data().actualManpower) - planned;
    }
    await ref.update(updates);
    return { message: 'Execution log updated', uid };
  }

  async deleteDailyLog(uid) {
    const ref = db.collection('execution_logs').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Execution log not found');
    await ref.update({ status: 'DELETED', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Execution log deleted' };
  }
}

export const executionService = new ExecutionService();
