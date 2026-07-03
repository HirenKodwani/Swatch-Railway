import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';
import logger from '../logger/index.js';

const VALID_STATUSES = ['pending', 'in_progress', 'completed', 'partially_completed', 'rejected', 'resubmitted', 'approved'];
const VALID_SHIFTS = ['morning', 'afternoon', 'night', 'all'];

class DailyActivityService {
  // ─── Create Activity Record ────────────────────────────────────────────────
  async createRecord(user, data) {
    const { stationId, areaId, activityId, date, shift, scheduledFrequency } = data;
    if (!stationId || !areaId || !activityId || !date || !shift) {
      throw new ValidationError('stationId, areaId, activityId, date, and shift are required');
    }

    const [stationDoc, areaDoc, activityDoc] = await Promise.all([
      db.collection('stations').doc(stationId).get(),
      db.collection('stationAreas').doc(areaId).get(),
      db.collection('activities').doc(activityId).get(),
    ]);
    if (!stationDoc.exists) throw new NotFoundError('Station not found');

    const stationName = stationDoc.data().stationName || '';
    const areaName = areaDoc.exists ? (areaDoc.data().name || '') : data.areaName || '';
    const activityName = activityDoc.exists ? (activityDoc.data().name || '') : data.activityName || '';

    const ref = db.collection('station_daily_activities').doc();
    const now = new Date().toISOString();
    const record = {
      uid: ref.id,
      stationId, stationName,
      areaId, areaName,
      activityId, activityName,
      date,
      shift: shift.toLowerCase(),
      scheduledFrequency: scheduledFrequency || 'once_per_day',
      status: 'pending',
      beforePhotoUrl: data.beforePhotoUrl || '',
      afterPhotoUrl: data.afterPhotoUrl || '',
      remarks: data.remarks || '',
      submittedBy: user.uid,
      submittedByName: user.fullName || user.name || '',
      submittedAt: null,
      verifiedBy: null,
      verifiedByName: null,
      verifiedAt: null,
      rejectionReason: null,
      resubmissionRemarks: null,
      auditLog: [{ action: 'CREATED', by: user.uid, byName: user.fullName || '', at: now }],
      createdAt: now,
      updatedAt: now,
    };
    await ref.set(record);
    logger.info('DailyActivity', `Record created: ${ref.id} for ${stationId}/${areaName}/${activityName}`);
    return { message: 'Activity record created', uid: ref.id, record };
  }

  // ─── Update Activity Status ───────────────────────────────────────────────
  async updateStatus(uid, status, user, extra = {}) {
    if (!VALID_STATUSES.includes(status)) {
      throw new ValidationError(`status must be one of: ${VALID_STATUSES.join(', ')}`);
    }
    const ref = db.collection('station_daily_activities').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Activity record not found');

    const current = doc.data();
    const now = new Date().toISOString();

    const transitions = {
      pending: ['in_progress', 'completed', 'partially_completed'],
      in_progress: ['completed', 'partially_completed'],
      completed: ['approved', 'rejected'],
      partially_completed: ['approved', 'rejected'],
      rejected: ['resubmitted'],
      resubmitted: ['approved', 'rejected'],
      approved: [],
    };
    if (!transitions[current.status]?.includes(status)) {
      throw new ValidationError(`Cannot transition from '${current.status}' to '${status}'`);
    }

    const updates = {
      status,
      updatedAt: now,
      auditLog: admin.firestore.FieldValue.arrayUnion({
        action: status.toUpperCase(), by: user.uid, byName: user.fullName || '', at: now,
        details: extra.remarks || extra.rejectionReason || '',
      }),
    };

    if (status === 'completed' || status === 'partially_completed') {
      updates.submittedAt = now;
      if (extra.afterPhotoUrl) updates.afterPhotoUrl = extra.afterPhotoUrl;
      if (extra.beforePhotoUrl) updates.beforePhotoUrl = extra.beforePhotoUrl;
      if (extra.remarks) updates.remarks = extra.remarks;
    }
    if (status === 'approved' || status === 'rejected') {
      updates.verifiedBy = user.uid;
      updates.verifiedByName = user.fullName || '';
      updates.verifiedAt = now;
    }
    if (status === 'rejected' && extra.rejectionReason) {
      updates.rejectionReason = extra.rejectionReason;
    }
    if (status === 'resubmitted' && extra.resubmissionRemarks) {
      updates.resubmissionRemarks = extra.resubmissionRemarks;
      updates.rejectionReason = null;
    }

    await ref.update(updates);
    return { message: `Status updated to ${status}`, uid, status };
  }

  // ─── List Activities ──────────────────────────────────────────────────────
  async listActivities(query = {}) {
    const { stationId, areaId, activityId, date, shift, status, limit = 100, cursor } = query;
    let q = db.collection('station_daily_activities');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (areaId) q = q.where('areaId', '==', areaId);
    if (activityId) q = q.where('activityId', '==', activityId);
    if (date) q = q.where('date', '==', date);
    if (shift && shift !== 'all') q = q.where('shift', '==', shift.toLowerCase());
    if (status) q = q.where('status', '==', status);
    const result = await paginate(q, { limit, cursor, orderBy: 'createdAt', orderDir: 'desc' });
    return { count: result.items.length, activities: result.items, pagination: result.pagination };
  }

  // ─── Get Activity by ID ───────────────────────────────────────────────────
  async getById(uid) {
    const doc = await db.collection('station_daily_activities').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Activity record not found');
    return { id: doc.id, ...doc.data() };
  }

  // ─── Get Missed Activities (Exception Detection) ──────────────────────────
  async getMissedActivities(stationId, date, shift) {
    if (!stationId || !date) throw new ValidationError('stationId and date are required');

    // Fetch all activity-area-frequency mappings for this station
    const [areasSnap, activitiesSnap, schedulesSnap] = await Promise.all([
      db.collection('stationAreas').where('stationId', '==', stationId).get(),
      db.collection('activities').where('active', '==', true).limit(100).get(),
      db.collection('stationSchedules').where('stationId', '==', stationId).get(),
    ]);

    // Get all completed/approved records for today
    let doneQuery = db.collection('station_daily_activities')
      .where('stationId', '==', stationId)
      .where('date', '==', date)
      .where('status', 'in', ['completed', 'approved', 'partially_completed']);
    if (shift && shift !== 'all') doneQuery = doneQuery.where('shift', '==', shift.toLowerCase());
    const doneSnap = await doneQuery.get();

    const doneKeys = new Set();
    doneSnap.forEach(doc => {
      const d = doc.data();
      doneKeys.add(`${d.areaId}_${d.activityId}_${d.shift}`);
    });

    const missed = [];
    schedulesSnap.forEach(doc => {
      const s = doc.data();
      const shiftMatch = !shift || shift === 'all' || s.shift === shift;
      if (!shiftMatch) return;
      const key = `${s.areaId}_${s.activityId || ''}_${s.shift}`;
      if (!doneKeys.has(key)) {
        missed.push({
          stationId, date,
          areaId: s.areaId, areaName: s.areaName || '',
          activityId: s.activityId || '', activityName: s.activityName || '',
          shift: s.shift, frequency: s.frequency,
          scheduledId: doc.id,
          missedAt: new Date().toISOString(),
        });
      }
    });

    return { stationId, date, shift: shift || 'all', missedCount: missed.length, missed };
  }

  // ─── Get Pending Activities (Worker view) ─────────────────────────────────
  async getPendingActivities(stationId, date, shift, workerId) {
    if (!stationId || !date) throw new ValidationError('stationId and date are required');
    let q = db.collection('station_daily_activities')
      .where('stationId', '==', stationId)
      .where('date', '==', date)
      .where('status', 'in', ['pending', 'rejected', 'in_progress']);
    if (shift && shift !== 'all') q = q.where('shift', '==', shift.toLowerCase());
    if (workerId) q = q.where('submittedBy', '==', workerId);
    const snapshot = await q.limit(200).get();
    const activities = [];
    snapshot.forEach(doc => activities.push({ id: doc.id, ...doc.data() }));
    return { stationId, date, count: activities.length, activities };
  }

  // ─── Get Shift Summary ────────────────────────────────────────────────────
  async getShiftSummary(stationId, date, shift) {
    if (!stationId || !date || !shift) throw new ValidationError('stationId, date, shift are required');
    const snapshot = await db.collection('station_daily_activities')
      .where('stationId', '==', stationId)
      .where('date', '==', date)
      .where('shift', '==', shift.toLowerCase()).get();

    const summary = { total: 0, pending: 0, in_progress: 0, completed: 0, partially_completed: 0, approved: 0, rejected: 0, resubmitted: 0 };
    snapshot.forEach(doc => {
      summary.total++;
      const s = doc.data().status;
      if (summary[s] !== undefined) summary[s]++;
    });
    const completionRate = summary.total > 0
      ? Math.round(((summary.completed + summary.approved + summary.partially_completed) / summary.total) * 100)
      : 0;

    return { stationId, date, shift, summary, completionRate };
  }

  // ─── Approve / Reject (bulk) ──────────────────────────────────────────────
  async bulkVerify(uids, status, user, remarks) {
    if (!['approved', 'rejected'].includes(status)) throw new ValidationError('status must be approved or rejected');
    const now = new Date().toISOString();
    const batch = db.batch();
    let count = 0;
    for (const uid of uids) {
      const ref = db.collection('station_daily_activities').doc(uid);
      batch.update(ref, {
        status, verifiedBy: user.uid, verifiedByName: user.fullName || '',
        verifiedAt: now, updatedAt: now,
        rejectionReason: status === 'rejected' ? (remarks || 'No reason given') : null,
        auditLog: admin.firestore.FieldValue.arrayUnion({
          action: status.toUpperCase(), by: user.uid, byName: user.fullName || '',
          at: now, details: remarks || '',
        }),
      });
      count++;
    }
    await batch.commit();
    return { message: `${count} activities ${status}`, count, status };
  }
}

export const dailyActivityService = new DailyActivityService();
