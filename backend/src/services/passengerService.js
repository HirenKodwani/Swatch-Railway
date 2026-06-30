import { db } from '../database/index.js';
import { NotFoundError, ValidationError, FirestoreError } from '../errors/index.js';

class PassengerService {
  async submitFeedback(userData, body) {
    const { taskId, passengerScore, passengerPhone, feedbackText } = body;
    if (!taskId) throw new ValidationError('taskId is required');
    const taskRef = db.collection('task_instances').doc(taskId);
    const doc = await taskRef.get();
    if (!doc.exists) throw new NotFoundError('Task not found');
    const taskData = doc.data();
    const supScore = taskData.supervisorScore || 0;
    const pScore = Number(passengerScore);
    if (isNaN(pScore)) throw new ValidationError('passengerScore must be a valid number');
    const consolidatedScore = (pScore * 0.7) + (supScore * 0.3);
    await taskRef.update({
      passengerScore: pScore,
      passengerPhone: passengerPhone || '',
      passengerFeedback: feedbackText || '',
      consolidatedScore,
      feedbackReceivedAt: new Date().toISOString()
    });
    return { success: true, message: 'Feedback submitted', consolidatedScore };
  }

  async getFeedbackList(filters = {}) {
    const { taskId, trainNo, coachNo } = filters;
    if (taskId) {
      const doc = await db.collection('task_instances').doc(taskId).get();
      if (!doc.exists) throw new NotFoundError('Task not found');
      return { feedback: doc.data() };
    }
    let query = db.collection('task_instances');
    if (trainNo) query = query.where('trainNo', '==', trainNo);
    if (coachNo) query = query.where('coachNo', '==', coachNo);
    const snapshot = await query.get();
    const feedbacks = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      if (data.passengerScore !== undefined || data.passengerFeedback) {
        feedbacks.push({ id: doc.id, ...data });
      }
    });
    return { count: feedbacks.length, feedbacks };
  }
}

export const passengerService = new PassengerService();
