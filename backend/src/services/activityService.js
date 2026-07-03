import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

const VALID_ACTIVITY_TYPES = [
  'sweeping', 'mopping', 'washing', 'rag_picking', 'toilet_cleaning',
  'drain_cleaning', 'water_booth_cleaning', 'garbage_collection',
  'garbage_disposal', 'cobweb_removal', 'stain_removal', 'pest_control',
  'rodent_control', 'deep_cleaning', 'consumable_refill', 'inspection_closure'
];

class ActivityService {
  async createActivity(userData, body) {
    const { activityName, activityType, description, unit, defaultFrequency } = body;
    if (!activityName) throw new ValidationError('activityName is required');

    const ref = db.collection('activities').doc();
    const data = {
      uid: ref.id,
      activityName,
      activityType: activityType || 'other',
      description: description || '',
      unit: unit || '',
      defaultFrequency: defaultFrequency || '',
      status: 'active',
      createdBy: userData.uid,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Activity created', uid: ref.id, activity: data };
  }

  async getActivities(query = {}) {
    const { activityType, status, limit = 50, cursor } = query;
    let firestoreQuery = db.collection('activities');
    if (activityType) firestoreQuery = firestoreQuery.where('activityType', '==', activityType);
    if (status) firestoreQuery = firestoreQuery.where('status', '==', status);
    const result = await paginate(firestoreQuery, { limit, cursor, orderBy: 'activityName', orderDir: 'asc' });
    return { count: result.items.length, activities: result.items, pagination: result.pagination };
  }

  async getActivityById(uid) {
    const doc = await db.collection('activities').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Activity not found');
    return { id: doc.id, ...doc.data() };
  }

  async updateActivity(uid, body) {
    const ref = db.collection('activities').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Activity not found');
    const updates = {};
    const allowed = ['activityName', 'activityType', 'description', 'unit', 'defaultFrequency', 'status'];
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }
    updates.updatedAt = new Date().toISOString();
    await ref.update(updates);
    return { message: 'Activity updated', uid };
  }

  async deleteActivity(uid) {
    const ref = db.collection('activities').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Activity not found');
    await ref.update({ status: 'inactive', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Activity deactivated' };
  }
}

export const activityService = new ActivityService();
