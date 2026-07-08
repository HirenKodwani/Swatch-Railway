import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

const VALID_FREQUENCY_TYPES = [
  'once_per_day', 'twice_per_day', 'three_times_per_day',
  'every_six_hours', 'hourly', 'weekly', 'fortnightly',
  'monthly', 'as_and_when_required'
];

class FrequencyService {
  async createFrequency(userData, body) {
    const { frequencyName, frequencyType, timesPerDay, daysBetween, description } = body;
    if (!frequencyName) throw new ValidationError('frequencyName is required');

    const ref = db.collection('frequencies').doc();
    const data = {
      uid: ref.id,
      frequencyName,
      frequencyType: frequencyType || 'other',
      timesPerDay: timesPerDay || 0,
      daysBetween: daysBetween || 0,
      description: description || '',
      status: 'active',
      createdBy: userData.uid,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Frequency created', uid: ref.id, frequency: data };
  }

  async getFrequencies(query = {}) {
    const { status, limit = 50, cursor } = query;
    let firestoreQuery = db.collection('frequencies');
    if (status) firestoreQuery = firestoreQuery.where('status', '==', status);
    const result = await paginate(firestoreQuery, { limit, cursor, orderBy: 'frequencyName', orderDir: 'asc' });
    return { count: result.items.length, frequencies: result.items, pagination: result.pagination };
  }

  async getFrequencyById(uid) {
    const doc = await db.collection('frequencies').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Frequency not found');
    return { id: doc.id, ...doc.data() };
  }

  async updateFrequency(uid, body) {
    const ref = db.collection('frequencies').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Frequency not found');
    const updates = {};
    const allowed = ['frequencyName', 'frequencyType', 'timesPerDay', 'daysBetween', 'description', 'status'];
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }
    updates.updatedAt = new Date().toISOString();
    await ref.update(updates);
    return { message: 'Frequency updated', uid };
  }

  async deleteFrequency(uid) {
    const ref = db.collection('frequencies').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Frequency not found');
    await ref.update({ status: 'inactive', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Frequency deactivated' };
  }
}

export const frequencyService = new FrequencyService();
