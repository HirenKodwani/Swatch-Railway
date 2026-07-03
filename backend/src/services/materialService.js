import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

class MaterialService {
  async createMaterial(userData, body) {
    const { materialName, materialType, unit, stationId, openingBalance, reorderLevel, unitPrice } = body;
    if (!materialName || !materialType || !unit) {
      throw new ValidationError('materialName, materialType, and unit are required');
    }

    const ref = db.collection('materials').doc();
    const data = {
      uid: ref.id,
      materialName,
      materialType,
      unit,
      stationId: stationId || null,
      openingBalance: openingBalance || 0,
      currentStock: openingBalance || 0,
      reorderLevel: reorderLevel || 0,
      unitPrice: unitPrice || 0,
      status: 'active',
      createdBy: userData.uid,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Material created', uid: ref.id, material: data };
  }

  async getMaterials(query = {}) {
    const { stationId, materialType, status, limit = 50, cursor } = query;
    let firestoreQuery = db.collection('materials');
    if (stationId) firestoreQuery = firestoreQuery.where('stationId', '==', stationId);
    if (materialType) firestoreQuery = firestoreQuery.where('materialType', '==', materialType);
    if (status) firestoreQuery = firestoreQuery.where('status', '==', status);
    const result = await paginate(firestoreQuery, { limit, cursor, orderBy: 'materialName', orderDir: 'asc' });
    return { count: result.items.length, materials: result.items, pagination: result.pagination };
  }

  async getMaterialById(uid) {
    const doc = await db.collection('materials').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Material not found');
    return { id: doc.id, ...doc.data() };
  }

  async updateMaterial(uid, body) {
    const ref = db.collection('materials').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Material not found');
    const updates = {};
    const allowed = ['materialName', 'materialType', 'unit', 'stationId', 'reorderLevel', 'unitPrice', 'status'];
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }
    if (body.openingBalance !== undefined) {
      updates.openingBalance = body.openingBalance;
      const current = doc.data();
      const diff = body.openingBalance - (current.openingBalance || 0);
      updates.currentStock = (current.currentStock || 0) + diff;
    }
    updates.updatedAt = new Date().toISOString();
    await ref.update(updates);
    return { message: 'Material updated', uid };
  }

  async deleteMaterial(uid) {
    const ref = db.collection('materials').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Material not found');
    await ref.update({ status: 'inactive', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Material deactivated' };
  }

  async issueMaterial(userData, body) {
    const { materialId, quantity, issuedTo, stationId, remarks } = body;
    if (!materialId || !quantity || !issuedTo) {
      throw new ValidationError('materialId, quantity, and issuedTo are required');
    }

    const matRef = db.collection('materials').doc(materialId);
    const matDoc = await matRef.get();
    if (!matDoc.exists) throw new NotFoundError('Material not found');
    const matData = matDoc.data();

    const qty = Number(quantity);
    if (isNaN(qty) || qty <= 0) throw new ValidationError('quantity must be a positive number');
    if (qty > (matData.currentStock || 0)) throw new ValidationError('Insufficient stock');

    const logRef = db.collection('material_logs').doc();
    const logData = {
      uid: logRef.id,
      materialId,
      materialName: matData.materialName,
      materialType: matData.materialType,
      unit: matData.unit,
      transactionType: 'issue',
      quantity: qty,
      stockBefore: matData.currentStock || 0,
      stockAfter: (matData.currentStock || 0) - qty,
      issuedTo,
      stationId: stationId || matData.stationId,
      remarks: remarks || '',
      issuedBy: userData.uid,
      issuedByName: userData.fullName || '',
      createdAt: new Date().toISOString()
    };

    await matRef.update({
      currentStock: logData.stockAfter,
      updatedAt: new Date().toISOString()
    });
    await logRef.set(logData);

    return { message: 'Material issued', uid: logRef.id, transaction: logData };
  }

  async receiveMaterial(userData, body) {
    const { materialId, quantity, receivedFrom, stationId, remarks } = body;
    if (!materialId || !quantity || !receivedFrom) {
      throw new ValidationError('materialId, quantity, and receivedFrom are required');
    }

    const matRef = db.collection('materials').doc(materialId);
    const matDoc = await matRef.get();
    if (!matDoc.exists) throw new NotFoundError('Material not found');
    const matData = matDoc.data();

    const qty = Number(quantity);
    if (isNaN(qty) || qty <= 0) throw new ValidationError('quantity must be a positive number');

    const logRef = db.collection('material_logs').doc();
    const logData = {
      uid: logRef.id,
      materialId,
      materialName: matData.materialName,
      materialType: matData.materialType,
      unit: matData.unit,
      transactionType: 'receive',
      quantity: qty,
      stockBefore: matData.currentStock || 0,
      stockAfter: (matData.currentStock || 0) + qty,
      receivedFrom,
      stationId: stationId || matData.stationId,
      remarks: remarks || '',
      receivedBy: userData.uid,
      receivedByName: userData.fullName || '',
      createdAt: new Date().toISOString()
    };

    await matRef.update({
      currentStock: logData.stockAfter,
      updatedAt: new Date().toISOString()
    });
    await logRef.set(logData);

    return { message: 'Material received', uid: logRef.id, transaction: logData };
  }

  async getStockAlerts(query = {}) {
    let firestoreQuery = db.collection('materials')
      .where('status', '==', 'active');
    if (query.stationId) firestoreQuery = firestoreQuery.where('stationId', '==', query.stationId);
    const snapshot = await firestoreQuery.get();
    const alerts = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      if (data.reorderLevel && data.currentStock <= data.reorderLevel) {
        alerts.push({
          id: doc.id,
          materialName: data.materialName,
          materialType: data.materialType,
          unit: data.unit,
          currentStock: data.currentStock,
          reorderLevel: data.reorderLevel,
          stationId: data.stationId,
          shortage: data.reorderLevel - data.currentStock
        });
      }
    });
    return { count: alerts.length, alerts };
  }

  async getMaterialLogs(query = {}) {
    const { materialId, stationId, transactionType, limit = 50, cursor } = query;
    let firestoreQuery = db.collection('material_logs');
    if (materialId) firestoreQuery = firestoreQuery.where('materialId', '==', materialId);
    if (stationId) firestoreQuery = firestoreQuery.where('stationId', '==', stationId);
    if (transactionType) firestoreQuery = firestoreQuery.where('transactionType', '==', transactionType);
    const result = await paginate(firestoreQuery, { limit, cursor, orderBy: 'createdAt', orderDir: 'desc' });
    return { count: result.items.length, transactions: result.items, pagination: result.pagination };
  }
}

export const materialService = new MaterialService();
