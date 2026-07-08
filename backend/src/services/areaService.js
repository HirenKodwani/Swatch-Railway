import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

const VALID_AREA_TYPES = [
  'Toilet', 'Waiting Hall', 'Track', 'Escalator', 'Lift',
  'Dustbin', 'Water Booth', 'Parking', 'Entrance', 'Corridor',
  'Staircase', 'Office', 'Canteen', 'Concourse', 'FOB',
  'Circulating Area', 'Approach Road', 'Gardens',
  'Goods Platform/Goods Line', 'Drains', 'Other',
  'Platform Surface', 'Platform Toilet', 'Water Booth Zone',
  'Dustbin Zone', 'Track Side', 'Bench Area', 'Signage Area'
];

const PLATFORM_AREA_TYPES = ['Platform Surface', 'Platform Toilet', 'Water Booth Zone', 'Dustbin Zone', 'Track Side', 'Bench Area', 'Signage Area'];
const STATION_AREA_TYPES = ['Waiting Room', 'Station Toilet', 'FOB', 'Escalator', 'Lift', 'Parking', 'Garden', 'Office', 'Canteen', 'Concourse', 'Circulating Area', 'Goods Shed', 'Drains'];

const TENDER_FIELDS = ['section', 'sectionName', 'platformRef', 'surfaceType', 'areaSqft', 'shiftConsidered', 'tenderedAreaPerDay', 'cleaningInterval'];

const VALID_FREQUENCIES = ['hourly', '2hrs', '4hrs', 'daily'];

async function _generateAreaCode(stationId, platformId, areaType) {
  const stationDoc = await db.collection('stations').doc(stationId).get();
  const stationCode = stationDoc.exists ? (stationDoc.data().stationCode || stationDoc.data().stationName || 'STN') : 'STN';
  const prefix = stationCode.substring(0, 3).toUpperCase();
  if (platformId) {
    const platformDoc = await db.collection('platforms').doc(platformId).get();
    const platformNumber = platformDoc.exists ? (platformDoc.data().platformNumber || 'PF') : 'PF';
    return `${prefix}-PF${platformNumber}-${(areaType || 'AREA').substring(0, 5).toUpperCase().replace(/\s/g, '')}`;
  }
  return `${prefix}-STN-${(areaType || 'AREA').substring(0, 5).toUpperCase().replace(/\s/g, '')}`;
}

class AreaService {
  async createArea(userData, body) {
    const { stationId, platformId, areaName, areaType, frequency, priority,
            cleaningFrequency, frequencyTimes, supervisorId, defaultWorkers, defaultShift, qrCode } = body;
    if (!stationId || !areaName) throw new ValidationError('stationId and areaName are required');

    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');

    if (platformId) {
      const platformDoc = await db.collection('platforms').doc(platformId).get();
      if (!platformDoc.exists) throw new NotFoundError('Platform not found');
    }

    const cf = cleaningFrequency || frequency || 'daily';
    if (!VALID_FREQUENCIES.includes(cf)) {
      throw new ValidationError(`Invalid cleaningFrequency: ${cf}. Must be one of: ${VALID_FREQUENCIES.join(', ')}`);
    }

    if (frequencyTimes && (!Array.isArray(frequencyTimes) || frequencyTimes.length === 0)) {
      throw new ValidationError('frequencyTimes must be a non-empty array of time strings (HH:MM)');
    }

    const ref = db.collection('areas').doc();
    const areaCode = body.areaCode || await _generateAreaCode(stationId, platformId, areaType || 'Other');
    const data = {
      uid: ref.id, stationId,
      stationName: stationDoc.data().stationName || '',
      platformId: platformId || null,
      areaName, areaType: areaType || 'Other',
      areaCode,
      cleaningFrequency: cf,
      frequencyTimes: frequencyTimes || [],
      priority: Math.max(1, Math.min(5, Number(priority) || 3)),
      supervisorId: supervisorId || null,
      defaultWorkers: defaultWorkers || [],
      defaultShift: defaultShift || 'morning',
      qrCode: qrCode || null,
      status: 'active',
      createdBy: userData.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    for (const field of TENDER_FIELDS) {
      if (body[field] !== undefined) data[field] = body[field];
    }
    if (body.frequency !== undefined) data.frequency = body.frequency;
    await ref.set(data);
    return { message: 'Area created', uid: ref.id, area: data };
  }

  async configureArea(userData, body) {
    const { uid, ...updateData } = body;
    if (uid) {
      const ref = db.collection('areas').doc(uid);
      const doc = await ref.get();
      if (!doc.exists) throw new NotFoundError('Area not found');
      const updates = {};
      const allowed = ['areaName', 'areaType', 'areaCode', 'cleaningFrequency', 'frequencyTimes', 'priority',
                        'supervisorId', 'defaultWorkers', 'defaultShift', 'qrCode', 'status', 'surfaceType',
                        'areaSqft', 'platformId', ...TENDER_FIELDS];
      for (const key of allowed) {
        if (updateData[key] !== undefined) {
          if (key === 'cleaningFrequency' && !VALID_FREQUENCIES.includes(updateData[key])) {
            throw new ValidationError(`Invalid cleaningFrequency: ${updateData[key]}`);
          }
          updates[key] = updateData[key];
        }
      }
      if (updates.cleaningFrequency === undefined && updateData.frequency !== undefined) {
        updates.cleaningFrequency = updateData.frequency;
      }
      if (updateData.stationId) {
        const stationDoc = await db.collection('stations').doc(updateData.stationId).get();
        if (!stationDoc.exists) throw new NotFoundError('Station not found');
        updates.stationId = updateData.stationId;
        updates.stationName = stationDoc.data().stationName || '';
      }
      updates.updatedAt = new Date().toISOString();
      await ref.update(updates);
      return { message: 'Area configured', uid };
    }
    return this.createArea(userData, body);
  }

  async getAreas(query = {}) {
    const { stationId, platformId, areaType, status, section, supervisorId, limit = 50, cursor } = query;
    let firestoreQuery = db.collection('areas');
    if (stationId) firestoreQuery = firestoreQuery.where('stationId', '==', stationId);
    if (platformId) firestoreQuery = firestoreQuery.where('platformId', '==', platformId);
    if (areaType) firestoreQuery = firestoreQuery.where('areaType', '==', areaType);
    if (status) firestoreQuery = firestoreQuery.where('status', '==', status);
    if (section !== undefined) firestoreQuery = firestoreQuery.where('section', '==', Number(section));
    if (supervisorId) firestoreQuery = firestoreQuery.where('supervisorId', '==', supervisorId);
    const result = await paginate(firestoreQuery, { limit, cursor, orderBy: 'areaName', orderDir: 'asc' });
    return { count: result.items.length, areas: result.items, pagination: result.pagination };
  }

  async getAreasByHierarchy(query = {}) {
    const { stationId, platformId } = query;
    if (stationId && platformId) {
      return this.getAreasByPlatform(platformId);
    }
    if (stationId) {
      return this.getAreasByStation(stationId);
    }
    throw new ValidationError('stationId is required');
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
    const allowed = ['areaName', 'areaType', 'areaCode', 'cleaningFrequency', 'frequencyTimes', 'priority',
                      'supervisorId', 'defaultWorkers', 'defaultShift', 'qrCode', 'status', ...TENDER_FIELDS];
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = key === 'priority' ? Math.max(1, Math.min(5, Number(body[key]))) : body[key];
    }
    if (body.frequency !== undefined && updates.cleaningFrequency === undefined) {
      updates.cleaningFrequency = body.frequency;
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
