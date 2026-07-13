import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import logger from '../logger/index.js';

class NotificationService {
  // Requires composite Firestore index: collection `notifications`, fields `userId` ASC, `createdAt` DESC
  async getNotifications(userId, limit = 50, offset = 0) {
    try {
      const snapshot = await db.collection('notifications')
        .where('userId', '==', userId)
        .orderBy('createdAt', 'desc')
        .offset(offset)
        .limit(limit)
        .get();

      const notifications = [];
      snapshot.forEach(doc => {
        const data = doc.data();
        notifications.push({
          ...data,
          createdAt: data.createdAt?.toDate?.()?.toISOString() || data.createdAt || null,
        });
      });

      return { count: notifications.length, notifications };
    } catch (err) {
      // Fallback: If composite index is missing, fetch all notifications for user and sort in-memory
      if (
        err.code === 9 ||
        (typeof err.code === 'string' && ['failed_precondition', 'failed-precondition', 'FAILED_PRECONDITION'].includes(err.code)) ||
        (err.message && (err.message.includes('FAILED_PRECONDITION') || err.message.toLowerCase().includes('index')))
      ) {
        logger.warn('NotificationService', 'Missing index for notifications, using in-memory sort fallback', { userId });
        const fallbackSnapshot = await db.collection('notifications')
          .where('userId', '==', userId)
          .get();

        const notifications = [];
        fallbackSnapshot.forEach(doc => {
          const data = doc.data();
          notifications.push({
            ...data,
            createdAt: data.createdAt?.toDate?.()?.toISOString() || data.createdAt || null,
          });
        });

        // Sort by createdAt descending
        notifications.sort((a, b) => {
          const timeA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
          const timeB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
          return timeB - timeA;
        });

        // Slice for pagination
        const sliced = notifications.slice(offset, offset + limit);
        return { count: sliced.length, notifications: sliced };
      }
      throw err;
    }
  }

  async markAsRead(notificationId, userId) {
    const ref = db.collection('notifications').doc(notificationId);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Notification not found');

    await ref.update({ isRead: true });
    logger.info('NotificationService', `Notification ${notificationId} marked as read`, { userId });
    return { message: 'Notification marked as read' };
  }

  async markAllAsRead(userId) {
    const snapshot = await db.collection('notifications')
      .where('userId', '==', userId)
      .where('isRead', '==', false)
      .limit(200).get();

    if (snapshot.empty) return { message: '0 notifications marked as read' };

    const batch = db.batch();
    snapshot.forEach(doc => batch.update(doc.ref, { isRead: true }));
    await batch.commit();

    logger.info('NotificationService', `${snapshot.size} notifications marked as read`, { userId });
    return { message: `${snapshot.size} notifications marked as read` };
  }

  async getUnreadCount(userId) {
    const snapshot = await db.collection('notifications')
      .where('userId', '==', userId)
      .where('isRead', '==', false)
      .limit(200).get();

    return { count: snapshot.size };
  }

  async createNotification(userId, title, message, type = 'info', referenceId = null) {
    const ref = db.collection('notifications').doc();
    const notification = {
      uid: ref.id,
      userId,
      title,
      message,
      type,
      referenceId,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await ref.set(notification);
    logger.info('NotificationService', `Notification created for user ${userId}`, { type, title });
    return { uid: ref.id, ...notification, createdAt: new Date().toISOString() };
  }
}

export const notificationService = new NotificationService();
