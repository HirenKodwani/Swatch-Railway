import { db } from '../database/index.js';
import { NotFoundError, ValidationError, ForbiddenError, FirestoreError } from '../errors/index.js';

class ObhsService {
  async markAttendance(userData, body) {
    const allowedFields = ['runInstanceId', 'attendanceType', 'imageUrl', 'latitude', 'longitude', 'deviceTimestamp', 'mobileNumber', 'deviceId', 'livenessChallenge'];
    for (const key of Object.keys(body)) {
      if (!allowedFields.includes(key)) throw new ValidationError(`Invalid field: '${key}'`);
    }
    const { runInstanceId, attendanceType, imageUrl, latitude, longitude, deviceTimestamp, mobileNumber, deviceId } = body;
    if (!runInstanceId || !attendanceType || !imageUrl || !deviceTimestamp) {
      throw new ValidationError('runInstanceId, attendanceType, imageUrl, and deviceTimestamp are required.');
    }
    if (!['start', 'mid', 'end'].includes(attendanceType)) {
      throw new ValidationError("attendanceType must be 'start', 'mid', or 'end'");
    }
    const { uid: workerId, fullName: workerName } = userData;
    const finalWorkerName = workerName || 'Unknown Worker';
    let isLateAttendance = false;
    let lateByMinutes = 0;
    let firstAttendanceTime = null;

    try {
      if (runInstanceId && attendanceType === 'start') {
        const runSnap = await db.collection('RunInstance').doc(runInstanceId).get();
        if (runSnap.exists) {
          const runData = runSnap.data();
          firstAttendanceTime = runData.first_attendance_time;
          const currentTimestamp = new Date(deviceTimestamp || new Date().toISOString());
          if (!firstAttendanceTime) {
            firstAttendanceTime = currentTimestamp.toISOString();
            await db.collection('RunInstance').doc(runInstanceId).update({ first_attendance_time: firstAttendanceTime, updatedAt: new Date().toISOString() });
          } else {
            const diffMs = currentTimestamp.getTime() - new Date(firstAttendanceTime).getTime();
            const diffMins = Math.floor(diffMs / 60000);
            if (diffMins > 15) { isLateAttendance = true; lateByMinutes = diffMins - 15; }
          }
        }
      }
    } catch (winErr) { console.error('(Attendance Timing Engine) Error:', winErr); }

    const attendanceDocId = `${runInstanceId}_${workerId}`;
    const attendanceRef = db.collection('obhs_attendance').doc(attendanceDocId);
    const attendanceDoc = await attendanceRef.get();
    const attendanceEntry = {
      photoUrl: imageUrl, deviceTimestamp, serverTimestamp: new Date().toISOString(),
      location: (latitude && longitude) ? { latitude, longitude } : null,
      mobileNumber: mobileNumber || null, deviceId: deviceId || null,
      isLate: isLateAttendance, lateByMinutes,
      firstAttendanceReference: firstAttendanceTime,
      status: isLateAttendance ? 'LATE' : 'PRESENT'
    };

    if (!attendanceDoc.exists) {
      if (attendanceType !== 'start') throw new ValidationError("You must submit 'start' attendance first.");
      await attendanceRef.set({
        uid: attendanceDocId, runInstanceId, workerId, workerName: finalWorkerName,
        mobileNumber: mobileNumber || null, deviceId: deviceId || null,
        isStartMarked: true, isMidMarked: false, isEndMarked: false,
        attendanceStatus: isLateAttendance ? 'LATE' : 'PRESENT',
        lateByMinutes, firstAttendanceReference: firstAttendanceTime,
        identityAuditStatus: 'PENDING_VERIFICATION',
        startAttendance: attendanceEntry, midAttendance: null, endAttendance: null,
        createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
      });
      try {
        if (runInstanceId && attendanceType === 'start') {
          const runSnap2 = await db.collection('RunInstance').doc(runInstanceId).get();
          if (runSnap2.exists && runSnap2.data().status === 'ALLOCATED') {
            const runData2 = runSnap2.data();
            const totalWorkers = (runData2.coaches || []).filter(c => c.workerId).length;
            const attendSnap = await db.collection('obhs_attendance')
              .where('runInstanceId', '==', runInstanceId)
              .where('isStartMarked', '==', true).get();
            if (attendSnap.size >= totalWorkers && totalWorkers > 0) {
              await db.collection('RunInstance').doc(runInstanceId).update({ status: 'READY', updatedAt: new Date().toISOString() });
            }
          }
        }
      } catch (readyErr) { console.error('(Attendance->READY) Error:', readyErr.message); }
    } else {
      const currentData = attendanceDoc.data();
      const updateData = { updatedAt: new Date().toISOString() };
      if (attendanceType === 'start') throw new ValidationError('Start attendance already submitted.');
      const baseStartPhoto = currentData.startAttendance?.photoUrl;
      if (!baseStartPhoto) throw new ValidationError('Baseline image missing from DB.');
      if (attendanceType === 'mid') {
        if (currentData.midAttendance) throw new ValidationError('Mid attendance already submitted.');
        updateData.midAttendance = attendanceEntry;
        updateData.isMidMarked = true;
        updateData.identityAuditStatus = 'MID_VERIFIED';
      }
      if (attendanceType === 'end') {
        if (currentData.endAttendance) throw new ValidationError('End attendance already submitted.');
        updateData.endAttendance = attendanceEntry;
        updateData.isEndMarked = true;
        updateData.identityAuditStatus = 'VERIFIED_SUCCESS';
      }
      updateData.attendanceStatus = isLateAttendance ? 'LATE' : 'PRESENT';
      await attendanceRef.update(updateData);
    }
    return { success: true, message: `${attendanceType.toUpperCase()} attendance processed successfully.`, uid: attendanceDocId, isLate: isLateAttendance };
  }

  async getAttendance(filters = {}) {
    const { runInstanceId, callerId, role } = filters;
    let query = db.collection('obhs_attendance');
    if (runInstanceId) query = query.where('runInstanceId', '==', runInstanceId);
    const snapshot = await query.get();
    let records = [];
    snapshot.forEach(doc => records.push(doc.data()));
    const roleUpper = (role || '').toUpperCase();
    if (roleUpper === 'WORKER' || roleUpper === 'RAILWAY WORKER') records = records.filter(r => r.workerId === callerId);
    records.sort((a, b) => ((b.updatedAt || '') > (a.updatedAt || '') ? 1 : -1));
    return { count: records.length, records };
  }

  async submitComplaint(userData, body) {
    const { runInstanceId: bodyRunInstanceId, coachNo, category, description, photoUrl } = body;
    if (!coachNo || !category || !description) {
      throw new ValidationError('Coach number, category, and description are required.');
    }
    if (!userData || !userData.uid) throw new ForbiddenError('Unauthorized.');
    const workerId = userData.uid;
    const workerName = userData.fullName || 'Unknown';
    let runInstanceId = bodyRunInstanceId || userData.activeRunInstanceId;
    if (!runInstanceId) throw new ValidationError('No active run instance found.');
    const runDoc = await db.collection('RunInstance').doc(runInstanceId).get();
    if (!runDoc.exists) throw new NotFoundError('RunInstance not found.');
    const runData = runDoc.data();
    const complaintsRef = db.collection('obhs_complaints').doc();
    await complaintsRef.set({
      complaintId: complaintsRef.id, runInstanceId,
      trainNo: runData.trainNo || 'N/A', trainName: runData.trainName || 'N/A',
      coachNo, category, description, photoUrl: photoUrl || null,
      status: 'OPEN', date: new Date().toISOString().split('T')[0],
      createdAt: new Date().toISOString(),
      submittedBy: { uid: workerId, name: workerName, role: userData.role || 'Railway Worker' }
    });
    return { success: true, message: 'Complaint registered successfully', complaintId: complaintsRef.id };
  }

  async getComplaints(filters = {}) {
    const { status, runInstanceId } = filters;
    let query = db.collection('obhs_complaints');
    if (status) query = query.where('status', '==', status);
    if (runInstanceId) query = query.where('runInstanceId', '==', runInstanceId);
    const snapshot = await query.orderBy('createdAt', 'desc').get();
    const complaints = [];
    snapshot.forEach(doc => complaints.push(doc.data()));
    return { count: complaints.length, complaints };
  }

  async submitFeedback(userData, body) {
    const { feedbackType, runInstanceId, coachNo, ratings, remarks, passengerName, mobileNumber, inspectorName } = body;
    if (!runInstanceId || !coachNo || !ratings) throw new ValidationError('Required fields missing.');
    const feedbackRef = db.collection('obhs_feedbacks').doc();
    const totalStars = Object.values(ratings).reduce((a, b) => a + Number(b), 0);
    const overallRating = parseFloat((totalStars / 5).toFixed(2));
    const feedbackData = {
      feedbackId: feedbackRef.id,
      feedbackType: feedbackType || 'PASSENGER',
      runInstanceId, coachNo, ratings, overallRating,
      remarks: remarks || '', createdAt: new Date().toISOString()
    };
    if (feedbackType === 'OFFICIAL') {
      feedbackData.inspectorName = inspectorName || userData.fullName;
    } else {
      feedbackData.passengerName = passengerName || 'Anonymous';
      feedbackData.mobileNumber = mobileNumber || '';
    }
    await feedbackRef.set(feedbackData);
    return { success: true, message: 'Feedback submitted.', overallRating };
  }

  async getFeedbacks(filters = {}) {
    const { workerId } = filters;
    if (!workerId) throw new ValidationError('workerId required.');
    const snapshot = await db.collection('obhs_feedbacks').get();
    const feedbacks = [];
    snapshot.forEach(doc => {
      const d = doc.data();
      if (d.targetWorker === workerId || d.coachNo) feedbacks.push(d);
    });
    const avgRating = feedbacks.length > 0
      ? parseFloat((feedbacks.reduce((s, f) => s + (f.overallRating || 0), 0) / feedbacks.length).toFixed(2))
      : 0;
    return { count: feedbacks.length, averageRating: avgRating, feedbacks };
  }

  async getWorkerStats(workerId) {
    if (!workerId) throw new ValidationError('workerId is required.');
    const [taskSnap, ratingSnap] = await Promise.all([
      db.collection('obhs_tasks').where('submittedBy.id', '==', workerId).get(),
      db.collection('worker_ratings').where('workerId', '==', workerId).get()
    ]);
    const taskStats = { total: 0, completed: 0 };
    taskSnap.forEach(doc => {
      const t = doc.data();
      taskStats.total++;
      if (t.status === 'Completed') taskStats.completed++;
    });
    let totalScore = 0, ratingCount = 0;
    const categories = {};
    ratingSnap.forEach(doc => {
      const d = doc.data();
      totalScore += Number(d.score) || 0;
      ratingCount++;
      if (!categories[d.category]) categories[d.category] = { total: 0, count: 0 };
      categories[d.category].total += Number(d.score) || 0;
      categories[d.category].count++;
    });
    return {
      workerId,
      taskStats: {
        totalTasks: taskStats.total,
        completedTasks: taskStats.completed,
        completionRate: taskStats.total > 0 ? parseFloat(((taskStats.completed / taskStats.total) * 100).toFixed(2)) : 0
      },
      ratingStats: {
        averageScore: ratingCount > 0 ? parseFloat((totalScore / ratingCount).toFixed(2)) : 0,
        totalRatings: ratingCount,
        categoryBreakdown: Object.entries(categories).map(([k, v]) => ({
          category: k,
          average: parseFloat((v.total / v.count).toFixed(2)),
          count: v.count
        }))
      }
    };
  }
}

export const obhsService = new ObhsService();
