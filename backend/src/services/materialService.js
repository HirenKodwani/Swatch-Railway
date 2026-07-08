import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

class MaterialService {
  async createMaterial(userData, body) {
    const { materialName, materialType, unit, stationId, openingBalance, reorderLevel, unitPrice, monthlyRequirement, remarks } = body;
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
      issuedQuantity: 0,
      usedQuantity: 0,
      monthlyRequirement: monthlyRequirement || 0,
      reorderLevel: reorderLevel || 0,
      unitPrice: unitPrice || 0,
      remarks: remarks || '',
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
    const allowed = ['materialName', 'materialType', 'unit', 'stationId', 'reorderLevel', 'unitPrice', 'status', 'monthlyRequirement', 'remarks'];
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
      issuedQuantity: admin.firestore.FieldValue.increment(qty),
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

  async useMaterial(userData, body) {
    const { materialId, quantity, taskId, workerId, stationId, remarks } = body;
    if (!materialId || !quantity) {
      throw new ValidationError('materialId and quantity are required');
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
      transactionType: 'use',
      quantity: qty,
      stockBefore: matData.currentStock || 0,
      stockAfter: (matData.currentStock || 0) - qty,
      usedBy: workerId || userData.uid,
      taskId: taskId || null,
      stationId: stationId || matData.stationId,
      remarks: remarks || '',
      createdAt: new Date().toISOString()
    };

    await matRef.update({
      currentStock: logData.stockAfter,
      usedQuantity: admin.firestore.FieldValue.increment(qty),
      updatedAt: new Date().toISOString()
    });
    await logRef.set(logData);

    return { message: 'Material usage recorded', uid: logRef.id, transaction: logData };
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

  async createReorderRequest(userData, body) {
    const { materialId, quantity, reason, stationId } = body;
    if (!materialId || !quantity) throw new ValidationError('materialId and quantity are required');
    const materialDoc = await db.collection('materials').doc(materialId).get();
    if (!materialDoc.exists) throw new NotFoundError('Material not found');
    const material = materialDoc.data();
    const ref = db.collection('material_reorder_requests').doc();
    const data = {
      uid: ref.id, materialId, materialName: material.materialName,
      materialType: material.materialType, unit: material.unit,
      currentStock: material.currentStock || 0, requestedQuantity: quantity,
      reason: reason || '', stationId: stationId || material.stationId,
      requestedBy: userData.uid, requestedAt: new Date().toISOString(),
      status: 'PENDING', approvedBy: null, approvedAt: null, rejectionReason: null,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Reorder request created', uid: ref.id, request: data };
  }

  async approveReorderRequest(uid, userData, body) {
    const ref = db.collection('material_reorder_requests').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Reorder request not found');
    const { approved, rejectionReason } = body;
    const reqData = doc.data();
    if (approved === true) {
      await ref.update({ status: 'APPROVED', approvedBy: userData.uid, approvedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
      await db.collection('materials').doc(reqData.materialId).update({
        currentStock: admin.firestore.FieldValue.increment(reqData.requestedQuantity),
        updatedAt: new Date().toISOString()
      });
      await db.collection('material_logs').add({
        materialId: reqData.materialId, materialName: reqData.materialName,
        transactionType: 'reorder_received', quantity: reqData.requestedQuantity,
        stockBefore: reqData.currentStock, stockAfter: reqData.currentStock + reqData.requestedQuantity,
        reorderRequestId: uid, performedBy: userData.uid, createdAt: new Date().toISOString()
      });
      return { message: 'Reorder approved and stock updated', uid: ref.id };
    } else {
      await ref.update({ status: 'REJECTED', rejectionReason: rejectionReason || 'No reason provided', approvedBy: userData.uid, approvedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
      return { message: 'Reorder request rejected', uid: ref.id };
    }
  }

  async listReorderRequests(query = {}) {
    const { stationId, materialId, status, limit = 50 } = query;
    let q = db.collection('material_reorder_requests');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (materialId) q = q.where('materialId', '==', materialId);
    if (status) q = q.where('status', '==', status);
    const snapshot = await q.orderBy('requestedAt', 'desc').limit(parseInt(limit)).get();
    return { count: snapshot.size, requests: snapshot.docs.map(d => d.data()) };
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
