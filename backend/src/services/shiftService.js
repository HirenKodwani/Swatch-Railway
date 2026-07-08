import { db } from '../database/index.js';
import { NotFoundError, ValidationError, ConflictError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

const VALID_SHIFT_TYPES = ['morning', 'afternoon', 'night'];
const VALID_SHIFT_TIMES = {
  morning: { start: '06:00', end: '14:00' },
  afternoon: { start: '14:00', end: '22:00' },
  night: { start: '22:00', end: '06:00' }
};

class ShiftService {
  async createShift(userData, body) {
    const { shiftType, stationId, customStartTime, customEndTime, maxWorkers, description } = body;
    if (!shiftType || !stationId) throw new ValidationError('shiftType and stationId are required');
    if (!VALID_SHIFT_TYPES.includes(shiftType.toLowerCase())) {
      throw new ValidationError(`shiftType must be one of: ${VALID_SHIFT_TYPES.join(', ')}`);
    }

    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');

    const existing = await db.collection('shifts')
      .where('shiftType', '==', shiftType.toLowerCase())
      .where('stationId', '==', stationId)
      .where('status', '==', 'active').limit(1).get();
    if (!existing.empty) throw new ConflictError(`Shift ${shiftType} already exists for this station`);

    const defaults = VALID_SHIFT_TIMES[shiftType.toLowerCase()];
    const ref = db.collection('shifts').doc();
    const data = {
      uid: ref.id, shiftType: shiftType.toLowerCase(),
      stationId, stationName: stationDoc.data().stationName || '',
      startTime: customStartTime || defaults.start,
      endTime: customEndTime || defaults.end,
      maxWorkers: Math.max(1, Number(maxWorkers) || 50),
      description: description || '',
      supervisors: [], workers: [],
      status: 'active',
      createdBy: userData.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Shift created', uid: ref.id, shift: data };
  }

  async getShifts(query = {}) {
    const { stationId, shiftType, status, limit = 50, cursor } = query;
    let firestoreQuery = db.collection('shifts');
    if (stationId) firestoreQuery = firestoreQuery.where('stationId', '==', stationId);
    if (shiftType) firestoreQuery = firestoreQuery.where('shiftType', '==', shiftType.toLowerCase());
    if (status) firestoreQuery = firestoreQuery.where('status', '==', status);
    const result = await paginate(firestoreQuery, { limit, cursor, orderBy: 'shiftType', orderDir: 'asc' });
    return { count: result.items.length, shifts: result.items, pagination: result.pagination };
  }

  async getShiftById(uid) {
    const doc = await db.collection('shifts').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Shift not found');
    return { id: doc.id, ...doc.data() };
  }

  async updateShift(uid, body) {
    const ref = db.collection('shifts').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Shift not found');
    const updates = {};
    const allowed = ['startTime', 'endTime', 'maxWorkers', 'description', 'status'];
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }
    updates.updatedAt = new Date().toISOString();
    await ref.update(updates);
    return { message: 'Shift updated', uid };
  }

  async deleteShift(uid) {
    const ref = db.collection('shifts').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Shift not found');
    await ref.update({ status: 'inactive', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Shift deactivated' };
  }

  async assignSupervisor(uid, supervisorId) {
    const shiftRef = db.collection('shifts').doc(uid);
    const shiftDoc = await shiftRef.get();
    if (!shiftDoc.exists) throw new NotFoundError('Shift not found');

    const userDoc = await db.collection('users').doc(supervisorId).get();
    if (!userDoc.exists) throw new NotFoundError('User not found');
    const userData = userDoc.data();

    const supervisors = shiftDoc.data().supervisors || [];
    if (!supervisors.find(s => s.uid === supervisorId)) {
      supervisors.push({ uid: supervisorId, name: userData.fullName || userData.name || 'Unknown', assignedAt: new Date().toISOString() });
      await shiftRef.update({ supervisors, updatedAt: new Date().toISOString() });
    }
    return { message: 'Supervisor assigned', uid };
  }

  async assignWorker(uid, workerId) {
    const shiftRef = db.collection('shifts').doc(uid);
    const shiftDoc = await shiftRef.get();
    if (!shiftDoc.exists) throw new NotFoundError('Shift not found');

    const userDoc = await db.collection('users').doc(workerId).get();
    if (!userDoc.exists) throw new NotFoundError('User not found');
    const userData = userDoc.data();

    const shiftData = shiftDoc.data();
    const workers = shiftData.workers || [];
    if (workers.length >= (shiftData.maxWorkers || 50)) throw new ValidationError('Shift already at maximum capacity');

    if (!workers.find(w => w.uid === workerId)) {
      workers.push({ uid: workerId, name: userData.fullName || userData.name || 'Unknown', assignedAt: new Date().toISOString() });
      await shiftRef.update({ workers, updatedAt: new Date().toISOString() });
    }
    return { message: 'Worker assigned', uid };
  }

  async removeAssignment(uid, userId) {
    const shiftRef = db.collection('shifts').doc(uid);
    const shiftDoc = await shiftRef.get();
    if (!shiftDoc.exists) throw new NotFoundError('Shift not found');
    const data = shiftDoc.data();
    const supervisors = (data.supervisors || []).filter(s => s.uid !== userId);
    const workers = (data.workers || []).filter(w => w.uid !== userId);
    await shiftRef.update({ supervisors, workers, updatedAt: new Date().toISOString() });
    return { message: 'User removed from shift' };
  }
}

export const shiftService = new ShiftService();
