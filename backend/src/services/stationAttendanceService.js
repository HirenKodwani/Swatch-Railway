import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError, ConflictError } from '../errors/index.js';
import logger from '../logger/index.js';

const VALID_SHIFTS = ['morning', 'afternoon', 'night'];
const VALID_STATUSES = ['present', 'absent', 'late', 'half_day', 'on_leave'];
const VALID_CAPTURE_MODES = ['biometric', 'manual', 'api'];

class StationAttendanceService {
  // ─── Mark Attendance ──────────────────────────────────────────────────────
  async markAttendance(user, data) {
    const { stationId, workerId, date, shift, captureMode, photoUrl, reason, workerName } = data;

    if (!stationId || !workerId || !date || !shift) {
      throw new ValidationError('stationId, workerId, date, and shift are required');
    }
    if (!VALID_SHIFTS.includes(shift.toLowerCase())) {
      throw new ValidationError(`shift must be one of: ${VALID_SHIFTS.join(', ')}`);
    }
    const mode = (captureMode || 'manual').toLowerCase();
    if (!VALID_CAPTURE_MODES.includes(mode)) {
      throw new ValidationError(`captureMode must be one of: ${VALID_CAPTURE_MODES.join(', ')}`);
    }

    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');

    const workerDoc = await db.collection('users').doc(workerId).get();
    const resolvedWorkerName = workerName
      || (workerDoc.exists ? (workerDoc.data().fullName || workerDoc.data().name) : 'Unknown Worker');

    const attendanceId = `${stationId}_${date}_${shift}_${workerId}`;
    const existingDoc = await db.collection('station_attendance').doc(attendanceId).get();
    if (existingDoc.exists) {
      throw new ConflictError(`Attendance already marked for worker ${workerId} on ${date} ${shift} shift`);
    }

    const now = new Date().toISOString();
    const shiftTimes = { morning: '06:00', afternoon: '14:00', night: '22:00' };
    const shiftStart = shiftTimes[shift.toLowerCase()];
    const currentHour = parseInt(now.split('T')[1].split(':')[0]);
    const shiftStartHour = parseInt(shiftStart.split(':')[0]);
    const isLate = currentHour > shiftStartHour + 1;

    const status = data.status || (isLate ? 'late' : 'present');
    if (!VALID_STATUSES.includes(status)) {
      throw new ValidationError(`status must be one of: ${VALID_STATUSES.join(', ')}`);
    }

    const record = {
      attendanceId,
      stationId,
      stationName: stationDoc.data().stationName || '',
      workerId,
      workerName: resolvedWorkerName,
      date,
      shift: shift.toLowerCase(),
      status,
      captureMode: mode,
      isManual: mode === 'manual',
      isLate,
      photoUrl: photoUrl || '',
      reason: reason || '',
      markedBy: user.uid,
      markedByName: user.fullName || user.name || '',
      markedAt: now,
      createdAt: now,
    };

    await db.collection('station_attendance').doc(attendanceId).set(record);
    logger.info('StationAttendance', `Attendance marked: ${workerId} @ ${stationId} on ${date} ${shift}`);
    return { message: 'Attendance marked successfully', attendanceId, record };
  }

  // ─── Bulk Mark Attendance ─────────────────────────────────────────────────
  async markBulkAttendance(user, data) {
    const { stationId, date, shift, workers } = data;
    if (!stationId || !date || !shift || !Array.isArray(workers) || workers.length === 0) {
      throw new ValidationError('stationId, date, shift, and workers array are required');
    }

    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');
    const stationName = stationDoc.data().stationName || '';

    const now = new Date().toISOString();
    const batch = db.batch();
    const results = [];

    for (const w of workers) {
      const attendanceId = `${stationId}_${date}_${shift}_${w.workerId}`;
      const existing = await db.collection('station_attendance').doc(attendanceId).get();
      if (existing.exists) {
        results.push({ workerId: w.workerId, status: 'skipped', reason: 'Already marked' });
        continue;
      }
      const record = {
        attendanceId, stationId, stationName,
        workerId: w.workerId, workerName: w.workerName || 'Unknown',
        date, shift: shift.toLowerCase(),
        status: w.status || 'present',
        captureMode: w.captureMode || 'manual',
        isManual: (w.captureMode || 'manual') === 'manual',
        isLate: false, photoUrl: w.photoUrl || '',
        reason: w.reason || '',
        markedBy: user.uid, markedByName: user.fullName || '',
        markedAt: now, createdAt: now,
      };
      batch.set(db.collection('station_attendance').doc(attendanceId), record);
      results.push({ workerId: w.workerId, status: 'marked', attendanceId });
    }
    await batch.commit();
    return { message: 'Bulk attendance processed', results };
  }

  // ─── Get Shift Attendance ─────────────────────────────────────────────────
  async getShiftAttendance(stationId, date, shift) {
    if (!stationId || !date) throw new ValidationError('stationId and date are required');

    let query = db.collection('station_attendance').where('stationId', '==', stationId).where('date', '==', date);
    if (shift) query = query.where('shift', '==', shift.toLowerCase());

    const snapshot = await query.orderBy('createdAt', 'desc').limit(500).get();
    const records = [];
    snapshot.forEach(doc => records.push(doc.data()));

    const summary = { total: records.length, present: 0, absent: 0, late: 0, halfDay: 0, onLeave: 0 };
    for (const r of records) {
      switch (r.status) {
        case 'present': summary.present++; break;
        case 'absent': summary.absent++; break;
        case 'late': summary.late++; break;
        case 'half_day': summary.halfDay++; break;
        case 'on_leave': summary.onLeave++; break;
      }
    }

    return { stationId, date, shift: shift || 'all', summary, records };
  }

  // ─── Planned vs Actual ────────────────────────────────────────────────────
  async getPlannedVsActual(stationId, date, shift) {
    if (!stationId || !date || !shift) throw new ValidationError('stationId, date, and shift are required');

    const planQuery = await db.collection('execution_plans')
      .where('stationId', '==', stationId)
      .where('status', '==', 'APPROVED')
      .orderBy('createdAt', 'desc').limit(1).get();

    let plannedCount = 0;
    if (!planQuery.empty) {
      const plan = planQuery.docs[0].data();
      const manpowerPlan = plan.manpowerPlan || {};
      plannedCount = manpowerPlan[shift.toLowerCase()] || manpowerPlan.planned || 0;
    }

    const attendanceSnap = await db.collection('station_attendance')
      .where('stationId', '==', stationId)
      .where('date', '==', date)
      .where('shift', '==', shift.toLowerCase()).get();

    let actualPresent = 0;
    attendanceSnap.forEach(doc => {
      const s = doc.data().status;
      if (s === 'present' || s === 'late') actualPresent++;
    });

    const variance = actualPresent - plannedCount;
    return {
      stationId, date, shift,
      planned: plannedCount,
      actual: actualPresent,
      variance,
      shortfall: Math.max(0, plannedCount - actualPresent),
      status: variance >= 0 ? 'ADEQUATE' : 'SHORTFALL',
    };
  }

  // ─── Get Monthly Summary ──────────────────────────────────────────────────
  async getMonthlySummary(stationId, month, year) {
    if (!stationId || !month || !year) throw new ValidationError('stationId, month, year are required');
    const monthPad = String(month).padStart(2, '0');
    const startDate = `${year}-${monthPad}-01`;
    const endDate = `${year}-${monthPad}-31`;

    const snapshot = await db.collection('station_attendance')
      .where('stationId', '==', stationId)
      .where('date', '>=', startDate)
      .where('date', '<=', endDate).get();

    const records = [];
    snapshot.forEach(doc => records.push(doc.data()));

    const workerMap = {};
    for (const r of records) {
      if (!workerMap[r.workerId]) {
        workerMap[r.workerId] = {
          workerId: r.workerId, workerName: r.workerName,
          present: 0, absent: 0, late: 0, halfDay: 0, onLeave: 0, total: 0,
        };
      }
      workerMap[r.workerId].total++;
      switch (r.status) {
        case 'present': workerMap[r.workerId].present++; break;
        case 'absent': workerMap[r.workerId].absent++; break;
        case 'late': workerMap[r.workerId].late++; break;
        case 'half_day': workerMap[r.workerId].halfDay++; break;
        case 'on_leave': workerMap[r.workerId].onLeave++; break;
      }
    }

    const workerSummaries = Object.values(workerMap);
    const totalDays = records.length > 0 ? [...new Set(records.map(r => r.date))].length : 0;
    const totalPresent = records.filter(r => r.status === 'present' || r.status === 'late').length;
    const totalAbsent = records.filter(r => r.status === 'absent').length;

    return {
      stationId, month, year,
      totalDays,
      totalRecords: records.length,
      totalPresent,
      totalAbsent,
      attendancePercentage: records.length > 0 ? Math.round((totalPresent / records.length) * 100) : 0,
      workerSummaries,
    };
  }

  // ─── Flag Absences ────────────────────────────────────────────────────────
  async flagAbsences(stationId, date, shift) {
    if (!stationId || !date || !shift) throw new ValidationError('stationId, date, shift are required');

    const shiftDoc = await db.collection('shifts')
      .where('stationId', '==', stationId)
      .where('shiftType', '==', shift.toLowerCase())
      .where('status', '==', 'active').limit(1).get();

    if (shiftDoc.empty) return { message: 'No active shift found for this station', flagged: 0 };

    const shiftData = shiftDoc.docs[0].data();
    const assignedWorkers = shiftData.workers || [];

    const attendanceSnap = await db.collection('station_attendance')
      .where('stationId', '==', stationId)
      .where('date', '==', date)
      .where('shift', '==', shift.toLowerCase()).get();

    const markedWorkerIds = new Set();
    attendanceSnap.forEach(doc => markedWorkerIds.add(doc.data().workerId));

    const batch = db.batch();
    let flagged = 0;
    const now = new Date().toISOString();

    for (const w of assignedWorkers) {
      if (!markedWorkerIds.has(w.uid)) {
        const attendanceId = `${stationId}_${date}_${shift}_${w.uid}`;
        const issueRef = db.collection('attendance_issues').doc();
        batch.set(issueRef, {
          uid: issueRef.id, stationId, workerId: w.uid, workerName: w.name,
          date, shift: shift.toLowerCase(),
          issueType: 'absent_not_marked',
          attendanceId,
          flaggedAt: now,
          resolved: false,
        });

        batch.set(db.collection('station_attendance').doc(attendanceId), {
          attendanceId, stationId, workerId: w.uid, workerName: w.name,
          date, shift: shift.toLowerCase(), status: 'absent',
          captureMode: 'auto_flag', isManual: false, isLate: false,
          photoUrl: '', reason: 'Auto-flagged as absent at shift end',
          markedBy: 'system', markedByName: 'System', markedAt: now, createdAt: now,
        }, { merge: true });
        flagged++;
      }
    }

    if (flagged > 0) await batch.commit();
    logger.info('StationAttendance', `Flagged ${flagged} absences for ${stationId} on ${date} ${shift}`);
    return { message: `${flagged} worker(s) flagged as absent`, flagged };
  }

  // ─── Update Attendance ────────────────────────────────────────────────────
  async updateAttendance(attendanceId, data, user) {
    const ref = db.collection('station_attendance').doc(attendanceId);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Attendance record not found');

    const allowed = ['status', 'reason', 'photoUrl'];
    const updates = { updatedAt: new Date().toISOString(), updatedBy: user.uid };
    for (const key of allowed) {
      if (data[key] !== undefined) updates[key] = data[key];
    }
    if (data.status && !VALID_STATUSES.includes(data.status)) {
      throw new ValidationError(`status must be one of: ${VALID_STATUSES.join(', ')}`);
    }
    await ref.update(updates);
    return { message: 'Attendance updated', attendanceId };
  }

  // ─── Get Worker Attendance History ────────────────────────────────────────
  async getWorkerHistory(workerId, stationId, startDate, endDate) {
    if (!workerId) throw new ValidationError('workerId is required');
    let query = db.collection('station_attendance').where('workerId', '==', workerId);
    if (stationId) query = query.where('stationId', '==', stationId);
    if (startDate) query = query.where('date', '>=', startDate);
    if (endDate) query = query.where('date', '<=', endDate);
    const snapshot = await query.orderBy('date', 'desc').limit(200).get();
    const records = [];
    snapshot.forEach(doc => records.push(doc.data()));
    return { workerId, count: records.length, records };
  }
}

export const stationAttendanceService = new StationAttendanceService();
