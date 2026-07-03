import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import logger from '../logger/index.js';

class DivisionService {
  async createDivision(data) {
    const { name, zone, code, region } = data;
    if (!name || !zone) throw new ValidationError('Division name and zone are required');

    const ref = db.collection('divisions').doc();
    const division = {
      uid: ref.id,
      name,
      zone,
      code: code || name.substring(0, 3).toUpperCase(),
      region: region || null,
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await ref.set(division);
    logger.info('DivisionService', `Division created: ${name}`, { zone, code });
    return { message: 'Division created', divisionId: ref.id };
  }

  async getDivisions(filters = {}) {
    let query = db.collection('divisions');
    if (filters.zone) query = query.where('zone', '==', filters.zone);
    const snapshot = await query.limit(200).get();
    const divisions = [];
    snapshot.forEach(doc => divisions.push({ id: doc.id, ...doc.data() }));
    divisions.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    return { count: divisions.length, divisions };
  }

  async getDivisionById(id) {
    const doc = await db.collection('divisions').doc(id).get();
    if (!doc.exists) throw new NotFoundError('Division not found');
    return { division: { id: doc.id, ...doc.data() } };
  }

  async updateDivision(id, data) {
    const ref = db.collection('divisions').doc(id);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Division not found');

    const updateData = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.zone !== undefined) updateData.zone = data.zone;
    if (data.code !== undefined) updateData.code = data.code;
    if (data.region !== undefined) updateData.region = data.region;
    if (data.status !== undefined) updateData.status = data.status;
    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    await ref.update(updateData);
    logger.info('DivisionService', `Division ${id} updated`);
    return { message: 'Division updated' };
  }

  async deleteDivision(id) {
    const ref = db.collection('divisions').doc(id);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Division not found');

    const activeUsers = await db.collection('users')
      .where('division', '==', id)
      .where('status', '==', 'APPROVED')
      .limit(1)
      .get();

    if (!activeUsers.empty) {
      throw new ValidationError('Cannot delete division: active users are assigned to it');
    }

    const activeContracts = await db.collection('contracts')
      .where('divisionId', '==', id)
      .where('status', 'in', ['active', 'Active', 'ACTIVE'])
      .limit(1)
      .get();

    if (!activeContracts.empty) {
      throw new ValidationError('Cannot delete division: active contracts reference it');
    }

    await ref.delete();
    logger.info('DivisionService', `Division ${id} deleted`);
    return { message: 'Division deleted' };
  }
}

export const divisionService = new DivisionService();
