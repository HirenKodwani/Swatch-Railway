import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

const VALID_AREA_TYPES = [
  'Toilet', 'Waiting Hall', 'Track', 'Escalator', 'Lift',
  'Dustbin', 'Water Booth', 'Parking', 'Entrance', 'Corridor',
  'Staircase', 'Office', 'Canteen', 'Other'
];

const TENDER_FIELDS = ['section', 'sectionName', 'platformRef', 'surfaceType', 'areaSqft', 'shiftConsidered', 'tenderedAreaPerDay', 'cleaningInterval'];

class AreaService {
  async createArea(userData, body) {
    const { stationId, platformId, areaName, areaType, frequency, priority } = body;
    if (!stationId || !areaName) throw new ValidationError('stationId and areaName are required');

    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');

    if (platformId) {
      const platformDoc = await db.collection('platforms').doc(platformId).get();
      if (!platformDoc.exists) throw new NotFoundError('Platform not found');
    }

    const ref = db.collection('areas').doc();
    const data = {
      uid: ref.id, stationId,
      stationName: stationDoc.data().stationName || '',
      platformId: platformId || null,
      areaName, areaType: areaType || 'Other',
      frequency: frequency || 'daily',
      priority: Math.max(1, Math.min(5, Number(priority) || 3)),
      status: 'active',
      createdBy: userData.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    for (const field of TENDER_FIELDS) {
      if (body[field] !== undefined) data[field] = body[field];
    }
    await ref.set(data);
    return { message: 'Area created', uid: ref.id, area: data };
  }

  async getAreas(query = {}) {
    const { stationId, platformId, areaType, status, section, limit = 50, cursor } = query;
    let firestoreQuery = db.collection('areas');
    if (stationId) firestoreQuery = firestoreQuery.where('stationId', '==', stationId);
    if (platformId) firestoreQuery = firestoreQuery.where('platformId', '==', platformId);
    if (areaType) firestoreQuery = firestoreQuery.where('areaType', '==', areaType);
    if (status) firestoreQuery = firestoreQuery.where('status', '==', status);
    if (section !== undefined) firestoreQuery = firestoreQuery.where('section', '==', Number(section));
    const result = await paginate(firestoreQuery, { limit, cursor, orderBy: 'areaName', orderDir: 'asc' });
    return { count: result.items.length, areas: result.items, pagination: result.pagination };
  }

  async getAreaById(uid) {
    const doc = await db.collection('areas').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Area not found');
    return { id: doc.id, ...doc.data() };
  }

  async updateArea(uid, body) {
    const ref = db.collection('areas').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Area not found');
    const updates = {};
    const allowed = ['areaName', 'areaType', 'frequency', 'priority', 'status', ...TENDER_FIELDS];
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = key === 'priority' ? Math.max(1, Math.min(5, Number(body[key]))) : body[key];
    }
    if (body.stationId) {
      const stationDoc = await db.collection('stations').doc(body.stationId).get();
      if (!stationDoc.exists) throw new NotFoundError('Station not found');
      updates.stationId = body.stationId;
      updates.stationName = stationDoc.data().stationName || '';
    }
    if (body.platformId !== undefined) updates.platformId = body.platformId || null;
    updates.updatedAt = new Date().toISOString();
    await ref.update(updates);
    return { message: 'Area updated', uid };
  }

  async deleteArea(uid) {
    const ref = db.collection('areas').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Area not found');
    await ref.update({ status: 'inactive', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Area deactivated' };
  }

  async getAreasByStation(stationId, section) {
    if (!stationId) throw new ValidationError('stationId is required');
    let query = db.collection('areas').where('stationId', '==', stationId).where('status', '==', 'active');
    if (section !== undefined) query = query.where('section', '==', Number(section));
    const snapshot = await query.get();
    const areas = [];
    snapshot.forEach(doc => areas.push({ id: doc.id, ...doc.data() }));
    areas.sort((a, b) => (a.areaName || '').localeCompare(b.areaName || ''));
    return { count: areas.length, areas };
  }

  async getAreasByPlatform(platformId) {
    if (!platformId) throw new ValidationError('platformId is required');
    const snapshot = await db.collection('areas').where('platformId', '==', platformId).where('status', '==', 'active').get();
    const areas = [];
    snapshot.forEach(doc => areas.push({ id: doc.id, ...doc.data() }));
    areas.sort((a, b) => (a.areaName || '').localeCompare(b.areaName || ''));
    return { count: areas.length, areas };
  }
}

export const areaService = new AreaService();
