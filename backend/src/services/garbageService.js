import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

const VALID_WASTE_TYPES = ['wet', 'dry', 'hazardous', 'mixed', 'recyclable', 'sanitary', 'e_waste', 'other'];
const VALID_STATUSES = ['RECORDED', 'VERIFIED', 'APPROVED', 'DISPOSED', 'REJECTED'];
const VALID_DISPOSAL_METHODS = ['landfill', 'incineration', 'recycling', 'composting', 'treatment', 'contractor_pickup', 'other'];

class GarbageService {
  async createWasteType(userData, body) {
    const { wasteType, description, disposalMethod, hazardous, recyclingRate } = body;
    if (!wasteType) throw new ValidationError('wasteType is required');
    const ref = db.collection('waste_types').doc();
    const data = {
      uid: ref.id, wasteType, description: description || '',
      disposalMethod: disposalMethod || 'landfill',
      hazardous: hazardous || false, recyclingRate: recyclingRate || 0,
      active: true, createdBy: userData.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Waste type created', uid: ref.id, wasteType: data };
  }

  async listWasteTypes() {
    const snap = await db.collection('waste_types').where('active', '==', true).get();
    const items = [];
    snap.forEach(d => items.push(d.data()));
    return { count: items.length, wasteTypes: items };
  }

  async recordCollection(userData, body) {
    const { stationId, area, wasteType, quantityKg, segregationStatus, disposalMethod, disposalAgency, vehicleNo, collectionDate, collectionTime, wetKg, dryKg, hazardousKg, recyclableKg, notes, evidencePhotos } = body;
    if (!stationId || !wasteType || !quantityKg) throw new ValidationError('stationId, wasteType, quantityKg are required');
    if (!VALID_WASTE_TYPES.includes(wasteType)) throw new ValidationError(`wasteType must be one of: ${VALID_WASTE_TYPES.join(', ')}`);

    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');
    const stationName = stationDoc.data().stationName || '';

    const ref = db.collection('garbage_collections').doc();
    const record = {
      uid: ref.id, stationId, stationName, area: area || '',
      wasteType, quantityKg: parseFloat(quantityKg) || 0,
      segregationStatus: segregationStatus || 'segregated',
      disposalMethod: disposalMethod || '',
      disposalAgency: disposalAgency || '', vehicleNo: vehicleNo || '',
      wetKg: parseFloat(wetKg) || 0, dryKg: parseFloat(dryKg) || 0,
      hazardousKg: parseFloat(hazardousKg) || 0,
      recyclableKg: parseFloat(recyclableKg) || 0,
      collectionDate: collectionDate || new Date().toISOString().split('T')[0],
      collectionTime: collectionTime || new Date().toTimeString().split(' ')[0],
      notes: notes || '', evidencePhotos: evidencePhotos || [],
      recordedBy: userData.uid, recordedByName: userData.fullName || userData.name || '',
      status: 'RECORDED', verifiedBy: null, verifiedAt: null,
      approvedBy: null, approvedAt: null, disposedBy: null, disposedAt: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: new Date().toISOString()
    };
    await ref.set(record);
    return { message: 'Garbage collection recorded', uid: ref.id, collection: record };
  }

  async listCollections(query = {}) {
    const { stationId, wasteType, status, startDate, endDate, area, disposalMethod, limit = 50, cursor } = query;
    let q = db.collection('garbage_collections');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (wasteType) q = q.where('wasteType', '==', wasteType);
    if (status) q = q.where('status', '==', status);
    if (area) q = q.where('area', '==', area);
    if (disposalMethod) q = q.where('disposalMethod', '==', disposalMethod);
    if (startDate) q = q.where('collectionDate', '>=', startDate);
    if (endDate) q = q.where('collectionDate', '<=', endDate);
    const result = await paginate(q, { limit, cursor, orderBy: 'collectionDate', orderDir: 'desc' });
    return { count: result.items.length, collections: result.items, pagination: result.pagination };
  }

  async getCollectionById(uid) {
    const doc = await db.collection('garbage_collections').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Collection record not found');
    return { id: doc.id, ...doc.data() };
  }

  async updateCollection(uid, body) {
    const ref = db.collection('garbage_collections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Collection record not found');
    if (doc.data().status !== 'RECORDED') throw new ValidationError('Only RECORDED collections can be edited');
    const allowed = ['area', 'wasteType', 'quantityKg', 'segregationStatus', 'disposalMethod', 'disposalAgency', 'vehicleNo', 'wetKg', 'dryKg', 'hazardousKg', 'recyclableKg', 'notes', 'evidencePhotos'];
    const updates = { updatedAt: new Date().toISOString() };
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }
    await ref.update(updates);
    return { message: 'Collection updated', uid };
  }

  async verifyCollection(uid, userData) {
    const ref = db.collection('garbage_collections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Collection record not found');
    if (doc.data().status !== 'RECORDED') throw new ValidationError('Only RECORDED collections can be verified');
    await ref.update({ status: 'VERIFIED', verifiedBy: userData.uid, verifiedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Collection verified' };
  }

  async approveCollection(uid, userData) {
    const ref = db.collection('garbage_collections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Collection record not found');
    if (doc.data().status !== 'VERIFIED') throw new ValidationError('Only VERIFIED collections can be approved');
    await ref.update({ status: 'APPROVED', approvedBy: userData.uid, approvedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Collection approved' };
  }

  async markDisposed(uid, userData) {
    const ref = db.collection('garbage_collections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Collection record not found');
    if (doc.data().status !== 'APPROVED') throw new ValidationError('Only APPROVED collections can be marked disposed');
    await ref.update({ status: 'DISPOSED', disposedBy: userData.uid, disposedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Collection marked as disposed' };
  }

  async rejectCollection(uid, userData, body) {
    const ref = db.collection('garbage_collections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Collection record not found');
    if (!['RECORDED', 'VERIFIED'].includes(doc.data().status)) throw new ValidationError('Only RECORDED or VERIFIED collections can be rejected');
    await ref.update({ status: 'REJECTED', rejectionReason: body.reason || '', rejectedBy: userData.uid, rejectedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Collection rejected' };
  }

  async getGarbageReport(query = {}) {
    const { stationId, startDate, endDate, wasteType } = query;
    let q = db.collection('garbage_collections');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (wasteType) q = q.where('wasteType', '==', wasteType);
    if (startDate) q = q.where('collectionDate', '>=', startDate);
    if (endDate) q = q.where('collectionDate', '<=', endDate);
    const snap = await q.get();
    const records = [];
    snap.forEach(d => records.push(d.data()));
    const totalKg = records.reduce((s, r) => s + (r.quantityKg || 0), 0);
    const byWasteType = {}; const byStatus = {}; const byArea = {};
    records.forEach(r => {
      byWasteType[r.wasteType] = (byWasteType[r.wasteType] || 0) + (r.quantityKg || 0);
      byStatus[r.status] = (byStatus[r.status] || 0) + 1;
      if (r.area) byArea[r.area] = (byArea[r.area] || 0) + (r.quantityKg || 0);
    });
    return { totalRecords: records.length, totalKg, byWasteType, byStatus, byArea, records };
  }
}

export const garbageService = new GarbageService();
