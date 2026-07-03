import { Queue } from 'bullmq';

const connection = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379')
};

export const notificationQueue = new Queue('notifications', { connection });

export async function enqueueNotification(type, payload) {
  return notificationQueue.add(type, payload, {
    attempts: 3,
    backoff: { type: 'exponential', delay: 2000 }
  });
}
