import { db } from '../database/index.js';
import { NotFoundError, ValidationError, ForbiddenError, FirestoreError } from '../errors/index.js';

class TaskService {
  async getTasksForRun(requesterData, runInstanceId, filters = {}) {
    const { status, source } = filters;
    let query = db.collection('obhs_tasks');
    if (status) query = query.where('status', '==', status);
    if (runInstanceId) query = query.where('runInstanceId', '==', runInstanceId);
    const snapshot = await query.get();
    const tasks = [];
    snapshot.forEach(doc => tasks.push({ id: doc.id, ...doc.data() }));
    return { success: true, count: tasks.length, data: tasks };
  }

  async updateTaskStatus(uid, body) {
    const { action, supervisorScore, supervisorComments, rejectionReason } = body;
    if (!action) throw new ValidationError('Action is required');
    const taskRef = db.collection('obhs_tasks').doc(uid);
    const doc = await taskRef.get();
    if (!doc.exists) throw new NotFoundError('Task not found');

    if (action === 'APPROVE') {
      if (supervisorScore === undefined) throw new ValidationError('Supervisor score is required');
      await taskRef.update({
        status: 'APPROVED',
        supervisorScore: Number(supervisorScore),
        supervisorComments: supervisorComments || '',
        approvedBy: uid,
        approvedAt: new Date().toISOString()
      });
      return { success: true, message: 'Task approved and scored' };
    } else if (action === 'REJECT') {
      if (!rejectionReason) throw new ValidationError('Rejection reason is mandatory');
      await taskRef.update({
        status: 'REJECTED',
        rejectionReason,
        rejectedBy: uid,
        rejectedAt: new Date().toISOString()
      });
      return { success: true, message: 'Task rejected' };
    }

    throw new ValidationError('Invalid action. Use APPROVE or REJECT');
  }

  async getTaskSummary(runInstanceId) {
    let query = db.collection('obhs_tasks');
    if (runInstanceId) query = query.where('runInstanceId', '==', runInstanceId);
    const snapshot = await query.get();
    let total = 0, completed = 0;
    snapshot.forEach(doc => {
      total++;
      if (doc.data().status === 'Completed') completed++;
    });
    return {
      totalTasks: total,
      completedTasks: completed,
      pendingTasks: total - completed,
      completionRate: total > 0 ? parseFloat(((completed / total) * 100).toFixed(2)) : 0
    };
  }

  async createEmergencyTask(creatorData, body) {
    const allowedRoles = ['cts', 'railway supervisor', 'railway admin'];
    const userRole = (creatorData.role || '').toLowerCase();
    if (!allowedRoles.includes(userRole)) {
      throw new ForbiddenError('Only CTS/Supervisors can create emergency tasks');
    }
    const { trainNo, coachNo, taskType, description, priority } = body;
    if (!trainNo || !coachNo || !taskType) {
      throw new ValidationError('Train No, Coach No, and Task Type are required.');
    }
    const taskId = `emg_${Date.now()}`;
    const taskData = {
      taskId, trainNo, coachNo, taskType,
      description: description || 'Emergency Task',
      priority: priority || 'HIGH', status: 'OPEN',
      taskSource: 'CTS',
      createdBy: creatorData.uid,
      createdByName: creatorData.fullName,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    await db.collection('passenger_tasks').doc(taskId).set(taskData);
    return { success: true, message: 'Emergency task created successfully.', taskId };
  }

  async getEmergencyTasks(filters = {}) {
    const { trainNo } = filters;
    let query = db.collection('passenger_tasks');
    if (trainNo) query = query.where('trainNo', '==', trainNo);
    const snapshot = await query.get();
    const tasks = [];
    snapshot.forEach(doc => tasks.push({ uid: doc.id, ...doc.data() }));
    tasks.sort((a, b) => {
      const dateA = a.createdAt ? new Date(a.createdAt) : new Date(0);
      const dateB = b.createdAt ? new Date(b.createdAt) : new Date(0);
      return dateB - dateA;
    });
    return { success: true, count: tasks.length, tasks };
  }
}

export const taskService = new TaskService();
