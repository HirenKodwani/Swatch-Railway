import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import logger from '../logger/index.js';

class NotificationService {
  // Requires composite Firestore index: collection `notifications`, fields `userId` ASC, `createdAt` DESC
  async getNotifications(userId, limit = 50, offset = 0) {
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
