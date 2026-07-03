import { db } from '../database/index.js';
import { NotFoundError, ValidationError, ConflictError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

class PlatformService {
  async createPlatform(userData, body) {
    const { platformNumber, stationId, platformName } = body;
    if (!platformNumber || !stationId) throw new ValidationError('platformNumber and stationId are required');

    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');

    const existing = await db.collection('platforms')
      .where('stationId', '==', stationId)
      .where('platformNumber', '==', platformNumber)
      .where('status', '==', 'active').limit(1).get();
    if (!existing.empty) throw new ConflictError(`Platform ${platformNumber} already exists at this station`);

    const stationData = stationDoc.data();
    const ref = db.collection('platforms').doc();
    const data = {
      uid: ref.id, platformNumber, stationId,
      stationName: stationData.stationName || '',
      platformName: platformName || `Platform ${platformNumber}`,
      status: 'active',
      createdBy: userData.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Platform created', uid: ref.id, platform: data };
  }

  async getPlatforms(query = {}) {
    const { stationId, status, limit = 50, cursor } = query;
    let firestoreQuery = db.collection('platforms');
    if (stationId) firestoreQuery = firestoreQuery.where('stationId', '==', stationId);
    if (status) firestoreQuery = firestoreQuery.where('status', '==', status);
    else firestoreQuery = firestoreQuery.where('status', '==', 'active');
    const result = await paginate(firestoreQuery, { limit, cursor, orderBy: 'platformNumber', orderDir: 'asc' });
    return { count: result.items.length, platforms: result.items, pagination: result.pagination };
  }

  async getPlatformById(uid) {
    const doc = await db.collection('platforms').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Platform not found');
    return { id: doc.id, ...doc.data() };
  }

  async updatePlatform(uid, body) {
    const ref = db.collection('platforms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Platform not found');
    const updates = {};
    const allowed = ['platformNumber', 'platformName', 'status'];
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }
    if (body.stationId) {
      const stationDoc = await db.collection('stations').doc(body.stationId).get();
      if (!stationDoc.exists) throw new NotFoundError('Station not found');
      updates.stationId = body.stationId;
      updates.stationName = stationDoc.data().stationName || '';
    }
    updates.updatedAt = new Date().toISOString();
    await ref.update(updates);
    return { message: 'Platform updated', uid };
  }

  async deletePlatform(uid) {
    const ref = db.collection('platforms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Platform not found');
    await ref.update({ status: 'inactive', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Platform deactivated' };
  }

  async getPlatformsByStation(stationId) {
    if (!stationId) throw new ValidationError('stationId is required');
    const snapshot = await db.collection('platforms')
      .where('stationId', '==', stationId)
      .where('status', '==', 'active')
      .orderBy('platformNumber').get();
    const platforms = [];
    snapshot.forEach(doc => platforms.push({ id: doc.id, ...doc.data() }));
    return { count: platforms.length, platforms };
  }
}

export const platformService = new PlatformService();
