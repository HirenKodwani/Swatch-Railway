import admin from 'firebase-admin';
import { db } from '../database/index.js';

class FcmService {
  async sendPush(userId, title, body, data = {}) {
    try {
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;
      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) return null;

      const message = {
        token: fcmToken,
        notification: { title, body },
        data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)]))
      };
      return await admin.messaging().send(message);
    } catch {
      return null;
    }
  }

  async sendPushToTokens(tokens, title, body, data = {}) {
    if (!tokens || tokens.length === 0) return null;
    try {
      const message = {
        tokens: tokens.filter(Boolean),
        notification: { title, body },
        data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)]))
      };
      return await admin.messaging().sendEachForMulticast(message);
    } catch {
      return null;
    }
  }
}

export const fcmService = new FcmService();
