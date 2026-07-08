import { db } from '../database/index.js';
import { NotFoundError, ValidationError, ForbiddenError, ConflictError } from '../errors/index.js';

class V2Service {
  async #logAudit(params) {
    try {
      await db.collection('audit_logs').add({ ...params, timestamp: db.Timestamp() });
    } catch (_) {}
  }

  async getTaskMasters() {
    const snapshot = await db.collection('task_masters').orderBy('taskCode').get();
    const masters = [];
    snapshot.forEach(doc => masters.push(doc.data()));
    return { count: masters.length, taskMasters: masters };
  }

  async createTaskMaster(body, user) {
    if (!['CM', 'CA'].includes(user.role)) {
      throw new ForbiddenError('Only CM/CA can create task masters');
    }
    const { taskCode, taskName, category, subCategory, assignedRole, applicableCoachTypes,
      priority, frequencyRules, scheduledTime, checklistTemplate,
      requiresSupervisorVerification, conflictGroup } = body;

    if (!taskCode || !taskName || !assignedRole) {
      throw new ValidationError('taskCode, taskName, assignedRole are required');
    }

    const ref = db.collection('task_masters').doc(taskCode);
    const existing = await ref.get();
    if (existing.exists) {
      throw new ConflictError('Task master with this code already exists');
    }

    const data = {
      taskCode, taskName, category: category || 'custom', subCategory: subCategory || null,
      assignedRole, applicableCoachTypes: applicableCoachTypes || ['all'],
      priority: priority || 'medium', requiresSupervisorVerification: requiresSupervisorVerification || false,
      isComplaintDriven: false, conflictGroup: conflictGroup || taskCode,
      frequencyRules: frequencyRules || [], scheduledTime: scheduledTime || null,
      checklistTemplate: checklistTemplate || [],
      active: true, isSystem: false,
      createdBy: user.uid, createdByName: user.fullName,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);

    await this.#logAudit({
      action: 'TASK_MASTER_CREATED', entityType: 'task_masters',
      entityId: taskCode, actorId: user.uid, actorRole: user.role,
      actorName: user.fullName, newValue: data,
      details: `Created task master: ${taskName} (${taskCode})`
    });

    return { success: true, message: 'Task master created', taskCode };
  }

  async updateTaskMaster(taskCode, body, user) {
    if (!['CM', 'CA'].includes(user.role)) {
      throw new ForbiddenError('Only CM/CA can update task masters');
    }
    const ref = db.collection('task_masters').doc(taskCode);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Task master not found');

    const oldData = doc.data();
    const updates = body;
    delete updates.taskCode;
    delete updates.isSystem;
    updates.updatedAt = new Date().toISOString();
    updates.updatedBy = user.uid;

    await ref.update(updates);

    await this.#logAudit({
      action: 'TASK_MASTER_UPDATED', entityType: 'task_masters',
      entityId: taskCode, actorId: user.uid, actorRole: user.role,
      actorName: user.fullName, oldValue: oldData, newValue: { ...oldData, ...updates },
      details: `Updated task master: ${taskCode}`
    });

    return { success: true, message: 'Task master updated' };
  }

  async createAssignment(body) {
    const { runInstanceId, workerId, workerName, workerRole, coachNos } = body;
    const assignmentId = `${runInstanceId}_${workerId}`;
    await db.collection('v2_assignments').doc(assignmentId).set({
      assignmentId, runInstanceId, workerId, workerName, workerRole,
      coachNos: coachNos || [], status: 'ACTIVE',
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    });
    return { message: 'Assignment created', assignmentId };
  }

  async getAssignments(runInstanceId) {
    const snapshot = await db.collection('v2_assignments').where('runInstanceId', '==', runInstanceId).get();
    const assignments = [];
    snapshot.forEach(doc => assignments.push(doc.data()));
    return { count: assignments.length, assignments };
  }

  async getTasks(runInstanceId, queryParams) {
    const { status, workerId } = queryParams;
    let query = db.collection('task_instances').where('runInstanceId', '==', runInstanceId);
    if (status) query = query.where('status', '==', status);
    if (workerId) query = query.where('workerId', '==', workerId);
    const snapshot = await query.get();
    const tasks = [];
    snapshot.forEach(doc => tasks.push(doc.data()));
    return { count: tasks.length, tasks };
  }

  async startTask(body, user) {
    const { taskInstanceId } = body;
    await db.collection('task_instances').doc(taskInstanceId).update({
      status: 'IN_PROGRESS', startedAt: new Date().toISOString(), startedBy: user.uid
    });
    return { message: 'Task started' };
  }

  async submitTask(body, user) {
    const { taskInstanceId, beforePhoto, afterPhoto, gpsLatitude, gpsLongitude, remarks } = body;
    await db.collection('task_instances').doc(taskInstanceId).update({
      status: 'COMPLETED', beforePhoto, afterPhoto, gpsLatitude, gpsLongitude,
      remarks: remarks || '', completedAt: new Date().toISOString(), completedBy: user.uid
    });
    return { message: 'Task completed' };
  }

  async verifyTask(body, user) {
    const { taskInstanceId, verified, score, remarks } = body;
    await db.collection('task_instances').doc(taskInstanceId).update({
      status: verified ? 'VERIFIED' : 'REJECTED', supervisorScore: score,
      supervisorRemarks: remarks || '', verifiedAt: new Date().toISOString(), verifiedBy: user.uid
    });
    return { message: verified ? 'Task verified' : 'Task rejected' };
  }

  async closeTask(body) {
    const { taskInstanceId } = body;
    await db.collection('task_instances').doc(taskInstanceId).update({
      status: 'CLOSED', closedAt: new Date().toISOString()
    });
    return { message: 'Task closed' };
  }

  async reopenTask(body, user) {
    const { taskInstanceId } = body;
    await db.collection('task_instances').doc(taskInstanceId).update({
      status: 'OPEN', reopenedAt: new Date().toISOString(), reopenedBy: user.uid
    });
    return { message: 'Task reopened' };
  }

  async markTaskNotApplicable(body, user) {
    const { taskInstanceId, reason } = body;
    await db.collection('task_instances').doc(taskInstanceId).update({
      status: 'NA', naReason: reason, markedAt: new Date().toISOString(), markedBy: user.uid
    });
    return { message: 'Task marked N/A' };
  }

  async editTask(taskInstanceId, body, user) {
    const allowedRoles = ['CS', 'CTS', 'CA', 'CM'];
    if (!allowedRoles.includes(user.role)) {
      throw new ForbiddenError('Only CS/CTS/CA/CM can edit tasks');
    }

    const ref = db.collection('task_instances').doc(taskInstanceId);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Task instance not found');

    const oldData = doc.data();
    const updates = { ...body };

    delete updates.taskId;
    delete updates.runInstanceId;
    delete updates.isParentTask;
    delete updates.parentTaskId;
    delete updates.childTaskIds;
    delete updates.createdAt;

    if (updates.workerId && updates.workerId !== oldData.workerId) {
      if (!updates.workerName) {
        try {
          const workerDoc = await db.collection('users').doc(updates.workerId).get();
          if (workerDoc.exists) {
            updates.workerName = workerDoc.data().fullName || workerDoc.data().name || 'Unknown';
          }
        } catch (_) { updates.workerName = 'Unknown'; }
      }
    }

    updates.updatedAt = new Date().toISOString();
    updates.editedBy = user.uid;
    updates.editedByName = user.fullName;
    updates.editedAt = updates.updatedAt;

    await ref.update(updates);

    if (oldData.isParentTask && (updates.workerId || updates.workerName || updates.workerRole)) {
      const children = oldData.childTaskIds || [];
      const childBatch = db.batch();
      for (const cId of children) {
        const childRef = db.collection('task_instances').doc(cId);
        childBatch.update(childRef, {
          ...(updates.workerId && { workerId: updates.workerId }),
          ...(updates.workerName && { workerName: updates.workerName }),
          ...(updates.workerRole && { workerRole: updates.workerRole }),
          ...(updates.scheduledTime && { scheduledTime: updates.scheduledTime }),
          ...(updates.coachNo && { coachNo: updates.coachNo }),
          updatedAt: new Date().toISOString()
        });
      }
      await childBatch.commit();
    }

    await this.#logAudit({
      action: 'TASK_EDITED', entityType: 'task_instances',
      entityId: taskInstanceId, actorId: user.uid,
      actorRole: user.role, actorName: user.fullName,
      oldValue: oldData, newValue: { ...oldData, ...updates },
      details: `Supervisor ${user.fullName} edited task ${taskInstanceId}`
    });

    return { success: true, message: 'Task updated', taskInstanceId };
  }

  async getWorkerMyTasks(user, queryParams) {
    const { uid } = user;
    const { status } = queryParams;
    let query = db.collection('task_instances').where('workerId', '==', uid);
    if (status) query = query.where('status', '==', status);
    const snapshot = await query.get();
    const tasks = [];
    snapshot.forEach(doc => tasks.push(doc.data()));
    return { count: tasks.length, tasks };
  }

  async getJourneyTimeline(runInstanceId) {
    const runDoc = await db.collection('RunInstance').doc(runInstanceId).get();
    if (!runDoc.exists) throw new NotFoundError('Run not found');
    const runData = runDoc.data();
    const taskSnapshot = await db.collection('task_instances').where('runInstanceId', '==', runInstanceId).orderBy('scheduledTime').get();
    const timeline = [];
    taskSnapshot.forEach(doc => timeline.push(doc.data()));
    return { runInstanceId, trainNo: runData.trainNo, trainName: runData.trainName, status: runData.status, scheduledDeparture: runData.departureDate, tasks: timeline };
  }

  async getClosureTasks(runInstanceId) {
    const snapshot = await db.collection('task_instances').where('runInstanceId', '==', runInstanceId).where('category', '==', 'closure').get();
    const tasks = [];
    snapshot.forEach(doc => tasks.push(doc.data()));
    return { count: tasks.length, tasks };
  }

  async completeClosureTasks(body, user) {
    const { runInstanceId } = body;
    const snapshot = await db.collection('task_instances').where('runInstanceId', '==', runInstanceId).where('category', '==', 'closure').where('status', 'in', ['OPEN', 'IN_PROGRESS']).get();
    const batch = db.batch();
    snapshot.forEach(doc => batch.update(doc.ref, { status: 'COMPLETED', completedAt: new Date().toISOString(), completedBy: user.uid }));
    await batch.commit();
    return { message: `Completed ${snapshot.size} closure tasks` };
  }

  async createEscalation(body, user) {
    const { taskInstanceId, reason, escalatedTo } = body;
    const ref = db.collection('v2_escalations').doc();
    await ref.set({ uid: ref.id, taskInstanceId, reason, escalatedTo, escalatedBy: user.uid, escalatedByName: user.fullName, status: 'OPEN', createdAt: new Date().toISOString() });
    return { message: 'Escalation created', uid: ref.id };
  }

  async getEscalations(queryParams) {
    const { status } = queryParams;
    let query = db.collection('v2_escalations');
    if (status) query = query.where('status', '==', status);
    const snapshot = await query.orderBy('createdAt', 'desc').get();
    const escalations = [];
    snapshot.forEach(doc => escalations.push(doc.data()));
    return { count: escalations.length, escalations };
  }

  async resolveEscalation(escalationId, body, user) {
    const { resolution } = body;
    await db.collection('v2_escalations').doc(escalationId).update({ status: 'RESOLVED', resolution, resolvedAt: new Date().toISOString(), resolvedBy: user.uid });
    return { message: 'Escalation resolved' };
  }

  async getAuditLogs(queryParams) {
    const { entityType, entityId, limit: limitParam } = queryParams;
    let query = db.collection('audit_logs').orderBy('timestamp', 'desc');
    if (entityType) query = query.where('entityType', '==', entityType);
    if (entityId) query = query.where('entityId', '==', entityId);
    const snapshot = await query.limit(Number(limitParam) || 100).get();
    const logs = [];
    snapshot.forEach(doc => logs.push(doc.data()));
    return { count: logs.length, logs };
  }

  async submitPassengerFeedback(body) {
    const { passengerName, mobileNumber, coachNo, ratings, remarks, runInstanceId } = body;
    if (!runInstanceId || !coachNo || !ratings) throw new ValidationError('Required fields missing.');
    const { cleanliness, toiletHygiene, linenQuality, security, staffBehaviour } = ratings;
    if (cleanliness === undefined || toiletHygiene === undefined || linenQuality === undefined || security === undefined || staffBehaviour === undefined) {
      throw new ValidationError('All 5 rating parameters required.');
    }
    const runDoc = await db.collection('RunInstance').doc(runInstanceId).get();
    if (!runDoc.exists) throw new NotFoundError('Journey not found.');
    const runData = runDoc.data();
    const totalStars = Number(cleanliness) + Number(toiletHygiene) + Number(linenQuality) + Number(security) + Number(staffBehaviour);
    const overallRating = parseFloat((totalStars / 5).toFixed(2));
    const feedbackRef = db.collection('obhs_feedbacks').doc();
    await feedbackRef.set({ feedbackId: feedbackRef.id, feedbackType: 'QR_PASSENGER', runInstanceId, trainNo: runData.trainNo || 'UNKNOWN', trainName: runData.trainName || '', coachNo, passengerName: passengerName || 'Anonymous', mobileNumber: mobileNumber || 'N/A', remarks: remarks || '', ratings, overallRating, source: 'QR_CODE', createdAt: new Date().toISOString() });
    return { success: true, message: 'Thank you for your feedback!', overallRating };
  }
}

export const v2Service = new V2Service();
