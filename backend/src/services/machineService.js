import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

class MachineService {
  async createMachine(userData, body) {
    const { machineName, machineType, serialNumber, stationId } = body;
    if (!machineName || !machineType || !serialNumber || !stationId) throw new ValidationError('machineName, machineType, serialNumber, and stationId are required');
    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');
    const existing = await db.collection('machines').where('serialNumber', '==', serialNumber).where('status', '==', 'active').limit(1).get();
    if (!existing.empty) throw new ValidationError('Duplicate serial number');
    const ref = db.collection('machines').doc();
    const data = { uid: ref.id, machineName, machineType, serialNumber, stationId, stationName: stationDoc.data().stationName || '', location: body.location || '', workingStatus: body.workingStatus || 'working', maintenanceSchedule: body.maintenanceSchedule || '', hourlyRate: body.hourlyRate || 0, dailyRate: body.dailyRate || 0, downtimeEntry: null, replacementStatus: body.replacementStatus || 'none', remarks: body.remarks || '', status: 'active', createdBy: userData.uid, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() };
    await ref.set(data);
    return { message: 'Machine created', uid: ref.id, machine: data };
  }

  async getMachines(query = {}) {
    const { stationId, machineType, workingStatus, status, limit = 50, cursor } = query;
    let q = db.collection('machines');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (machineType) q = q.where('machineType', '==', machineType);
    if (workingStatus) q = q.where('workingStatus', '==', workingStatus);
    if (status) q = q.where('status', '==', status);
    const result = await paginate(q, { limit, cursor, orderBy: 'machineName', orderDir: 'asc' });
    return { count: result.items.length, machines: result.items, pagination: result.pagination };
  }

  async getMachineById(uid) {
    const doc = await db.collection('machines').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Machine not found');
    return { id: doc.id, ...doc.data() };
  }

  async updateMachine(uid, body) {
    const ref = db.collection('machines').doc(uid);
    if (!(await ref.get()).exists) throw new NotFoundError('Machine not found');
    const updates = {};
    const allowed = ['machineName', 'machineType', 'location', 'workingStatus', 'maintenanceSchedule', 'hourlyRate', 'dailyRate', 'downtimeEntry', 'replacementStatus', 'remarks', 'status'];
    for (const key of allowed) { if (body[key] !== undefined) updates[key] = body[key]; }
    updates.updatedAt = new Date().toISOString();
    await ref.update(updates);
    return { message: 'Machine updated', uid };
  }

  async deleteMachine(uid) {
    const ref = db.collection('machines').doc(uid);
    if (!(await ref.get()).exists) throw new NotFoundError('Machine not found');
    await ref.update({ status: 'inactive', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Machine deactivated' };
  }

  async deployMachine(userData, body) {
    const { machineId, stationId, areaId, deployedDate, shift } = body;
    if (!machineId || !stationId || !deployedDate) throw new ValidationError('machineId, stationId, and deployedDate are required');
    const machineDoc = await db.collection('machines').doc(machineId).get();
    if (!machineDoc.exists) throw new NotFoundError('Machine not found');
    const ref = db.collection('machine_deployments').doc();
    const data = { uid: ref.id, machineId, machineName: machineDoc.data().machineName, machineType: machineDoc.data().machineType, stationId, areaId: areaId || null, shift: shift || null, deployedDate, deployedBy: userData.uid, deployedAt: new Date().toISOString(), status: 'DEPLOYED', returnedAt: null, createdAt: new Date().toISOString() };
    await ref.set(data);
    await db.collection('machines').doc(machineId).update({ deployed: true, updatedAt: new Date().toISOString() });
    return { message: 'Machine deployed', uid: ref.id, deployment: data };
  }

  async returnMachine(uid, userData) {
    const ref = db.collection('machine_deployments').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Deployment not found');
    await ref.update({ status: 'RETURNED', returnedAt: new Date().toISOString(), returnedBy: userData.uid });
    return { message: 'Machine returned' };
  }

  async listDeployments(query = {}) {
    const { stationId, machineId, status, deployedDate, limit = 50 } = query;
    let q = db.collection('machine_deployments');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (machineId) q = q.where('machineId', '==', machineId);
    if (status) q = q.where('status', '==', status);
    if (deployedDate) q = q.where('deployedDate', '==', deployedDate);
    const snapshot = await q.orderBy('deployedAt', 'desc').limit(parseInt(limit)).get();
    return { count: snapshot.size, deployments: snapshot.docs.map(d => ({ id: d.id, ...d.data() })) };
  }

  async logDowntime(userData, body) {
    const { machineId, startTime, endTime, reason, downtimeType } = body;
    if (!machineId || !startTime || !reason) throw new ValidationError('machineId, startTime, and reason are required');
    const ref = db.collection('machine_downtime').doc();
    const data = { uid: ref.id, machineId, startTime, endTime: endTime || null, durationHours: endTime ? Math.round((new Date(endTime) - new Date(startTime)) / 3600000 * 100) / 100 : null, reason, downtimeType: downtimeType || 'breakdown', reportedBy: userData.uid, reportedAt: new Date().toISOString(), createdAt: new Date().toISOString() };
    await ref.set(data);
    await db.collection('machines').doc(machineId).update({ workingStatus: 'under_maintenance', downtimeEntry: data, updatedAt: new Date().toISOString() });
    return { message: 'Downtime logged', uid: ref.id, downtime: data };
  }

  async resolveDowntime(uid, body) {
    const ref = db.collection('machine_downtime').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Downtime record not found');
    const endTime = body.endTime || new Date().toISOString();
    const durationHours = Math.round((new Date(endTime) - new Date(doc.data().startTime)) / 3600000 * 100) / 100;
    await ref.update({ endTime, durationHours, resolution: body.resolution || '', resolvedAt: new Date().toISOString() });
    if (doc.data().machineId) {
      await db.collection('machines').doc(doc.data().machineId).update({ workingStatus: body.workingStatus || 'working', updatedAt: new Date().toISOString() });
    }
    return { message: 'Downtime resolved' };
  }

  async getDowntimeReport(query = {}) {
    const { stationId, machineId, startDate, endDate, limit = 100 } = query;
    let q = db.collection('machine_downtime');
    if (machineId) q = q.where('machineId', '==', machineId);
    if (startDate) q = q.where('startTime', '>=', startDate);
    if (endDate) q = q.where('startTime', '<=', endDate);
    const snapshot = await q.orderBy('startTime', 'desc').limit(parseInt(limit)).get();
    const records = []; snapshot.forEach(d => records.push(d.data()));
    const totalHours = records.reduce((s, r) => s + (r.durationHours || 0), 0);
    const penalties = Math.round(totalHours * (query.penaltyRate || 500));
    return { count: records.length, totalDowntimeHours: Math.round(totalHours * 100) / 100, estimatedPenalty: penalties, records };
  }

  async scheduleMaintenance(userData, body) {
    const { machineId, scheduledDate, maintenanceType, notes } = body;
    if (!machineId || !scheduledDate) throw new ValidationError('machineId and scheduledDate are required');
    const ref = db.collection('machine_maintenance').doc();
    const data = { uid: ref.id, machineId, scheduledDate, maintenanceType: maintenanceType || 'regular', notes: notes || '', status: 'SCHEDULED', performedAt: null, performedBy: null, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() };
    await ref.set(data);
    await db.collection('machines').doc(machineId).update({ maintenanceSchedule: scheduledDate, updatedAt: new Date().toISOString() });
    return { message: 'Maintenance scheduled', uid: ref.id, schedule: data };
  }

  async completeMaintenance(uid, userData, body) {
    const ref = db.collection('machine_maintenance').doc(uid);
    if (!(await ref.get()).exists) throw new NotFoundError('Maintenance record not found');
    await ref.update({ status: 'COMPLETED', performedAt: new Date().toISOString(), performedBy: userData.uid, notes: body.notes || '', updatedAt: new Date().toISOString() });
    return { message: 'Maintenance completed' };
  }

  async listMaintenance(query = {}) {
    const { machineId, status, limit = 50 } = query;
    let q = db.collection('machine_maintenance');
    if (machineId) q = q.where('machineId', '==', machineId);
    if (status) q = q.where('status', '==', status);
    const snapshot = await q.orderBy('scheduledDate', 'desc').limit(parseInt(limit)).get();
    return { count: snapshot.size, schedules: snapshot.docs.map(d => d.data()) };
  }
}

export const machineService = new MachineService();
