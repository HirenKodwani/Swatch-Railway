import { db } from '../database/index.js';
import { NotFoundError, ValidationError, ConflictError, ForbiddenError, FirestoreError } from '../errors/index.js';

class StationService {
  async getStations(query = {}) {
    const { zone, division, category, active, userRole, userZone, userDivision } = query;
    const snapshot = await db.collection('stations').limit(200).get();
    let stations = [];
    snapshot.forEach(doc => stations.push(doc.data()));
    const role = (userRole || '').toLowerCase();
    if (!role.includes('master')) {
      const divFilter = division || userDivision;
      if (divFilter) stations = stations.filter(s => s.division === divFilter);
    }
    if (zone) stations = stations.filter(s => s.zone === zone);
    if (category) stations = stations.filter(s => s.category === category);
    if (active !== undefined) stations = stations.filter(s => s.active === (active === 'true'));
    stations.sort((a, b) => (a.stationName || '').localeCompare(b.stationName || ''));
    return { count: stations.length, stations };
  }

  async createStation(userData, body) {
    const { stationCode, stationName, zone, division, category, stationType, active, latitude, longitude, address } = body;
    if (!stationCode || !stationName || !zone || !division) {
      throw new ValidationError('stationCode, stationName, zone, division are required');
    }
    const existing = await db.collection('stations').where('stationCode', '==', stationCode).limit(1).get();
    if (!existing.empty) throw new ConflictError(`Station with code ${stationCode} already exists`);
    const ref = db.collection('stations').doc();
    const data = {
      uid: ref.id, stationCode, stationName, zone, division,
      category: category || 'c', stationType: stationType || 'regular',
      active: active !== false,
      latitude: latitude || 0, longitude: longitude || 0, address: address || '',
      createdBy: userData.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Station created', uid: ref.id, station: data };
  }

  async updateStation(uid, body) {
    const ref = db.collection('stations').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Station not found');
    const updates = {};
    const allowedStationFields = ['stationName', 'category', 'stationType', 'active', 'latitude', 'longitude', 'address', 'zone', 'division'];
    for (const key of allowedStationFields) {
      if (body[key] !== undefined) updates[key] = body[key];
    }
    updates.updatedAt = new Date().toISOString();
    await ref.update(updates);
    return { message: 'Station updated' };
  }
}

export const stationService = new StationService();
