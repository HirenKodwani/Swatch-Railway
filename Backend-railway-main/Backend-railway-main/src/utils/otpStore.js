import firebaseAdmin from 'firebase-admin';
import { db } from '../database/index.js';

const otpStore = {
  _col: () => db.collection('_otpStore'),
  async set(key, value) {
    await this._col().doc(key).set({
      value,
      createdAt: firebaseAdmin.firestore.FieldValue.serverTimestamp(),
      expireAt: new Date(Date.now() + 300000).toISOString()
    });
  },
  async get(key) {
    const doc = await this._col().doc(key).get();
    if (!doc.exists) return undefined;
    const data = doc.data();
    if (data.expireAt && new Date(data.expireAt) < new Date()) {
      await this._col().doc(key).delete();
      return undefined;
    }
    return data.value;
  },
  async delete(key) {
    await this._col().doc(key).delete();
  }
};

export default otpStore;
