import { Worker } from 'bullmq';
import { notificationService } from '../services/notificationService.js';
import { fcmService } from '../services/fcmService.js';

const connection = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379')
};

const handler = async (job) => {
  const { type, userId, title, body, data } = job.data;
  switch (type) {
    case 'push':
      await fcmService.sendPush(userId, title, body, data);
      break;
    case 'in-app':
      await notificationService.create({ userId, title, message: body, type: data?.notificationType || 'info', referenceId: data?.referenceId, referenceType: data?.referenceType, priority: data?.priority || 'normal' });
      break;
    case 'email':
      await notificationService.sendEmail({ uid: userId, email: data?.email }, title, body);
      break;
  }
};

export const notificationWorker = new Worker('notifications', handler, { connection, concurrency: 5 });
