import { db } from '../database/index.js';
import { NotFoundError, FirestoreError, IndexError } from '../errors/index.js';
import logger from '../logger/index.js';

export class BaseRepository {
  constructor(collectionName) {
    this.collectionName = collectionName;
    this._col = () => db.collection(collectionName);
  }

  async findById(id) {
    try {
      const doc = await this._col().doc(id).get();
      if (!doc.exists) return null;
      return { id: doc.id, ...doc.data() };
    } catch (error) {
      this._handleError(error, 'findById');
    }
  }

  async findAll(filters = {}) {
    try {
      let query = this._col();
      for (const [field, value] of Object.entries(filters)) {
        if (value !== undefined && value !== null) {
          query = query.where(field, '==', value);
        }
      }
      const snapshot = await query.get();
      return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
      return this._handleError(error, 'findAll');
    }
  }

  async findOne(filters) {
    try {
      let query = this._col();
      for (const [field, value] of Object.entries(filters)) {
        if (value !== undefined && value !== null) {
          query = query.where(field, '==', value);
        }
      }
      const snapshot = await query.limit(1).get();
      if (snapshot.empty) return null;
      const doc = snapshot.docs[0];
      return { id: doc.id, ...doc.data() };
    } catch (error) {
      return this._handleError(error, 'findOne');
    }
  }

  async create(data) {
    try {
      const docRef = this._col().doc();
      const doc = { uid: docRef.id, ...data, createdAt: db.Timestamp() };
      await docRef.set(doc);
      return { id: docRef.id, ...doc };
    } catch (error) {
      return this._handleError(error, 'create');
    }
  }

  async createWithId(id, data) {
    try {
      const doc = { ...data, createdAt: db.Timestamp() };
      await this._col().doc(id).set(doc);
      return { id, ...doc };
    } catch (error) {
      return this._handleError(error, 'createWithId');
    }
  }

  async update(id, data) {
    try {
      const docRef = this._col().doc(id);
      const existing = await docRef.get();
      if (!existing.exists) throw new NotFoundError(`${this.collectionName} not found`);
      const updateData = { ...data, updatedAt: db.Timestamp() };
      await docRef.update(updateData);
      return { id, ...existing.data(), ...updateData };
    } catch (error) {
      return this._handleError(error, 'update');
    }
  }

  async delete(id) {
    try {
      const docRef = this._col().doc(id);
      const existing = await docRef.get();
      if (!existing.exists) throw new NotFoundError(`${this.collectionName} not found`);
      await docRef.delete();
      return true;
    } catch (error) {
      return this._handleError(error, 'delete');
    }
  }

  async findWithPagination(filters = {}, options = {}) {
    try {
      const { limit = 50, offset = null, orderBy = null, orderDir = 'desc' } = options;
      let query = this._col();

      for (const [field, value] of Object.entries(filters)) {
        if (value !== undefined && value !== null) {
          query = query.where(field, '==', value);
        }
      }

      if (orderBy) {
        query = query.orderBy(orderBy, orderDir);
      }

      if (limit) query = query.limit(limit);

      const snapshot = await query.get();
      const docs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      return { data: docs, count: docs.length, limit };
    } catch (error) {
      return this._handleError(error, 'findWithPagination');
    }
  }

  _handleError(error, operation) {
    if (error instanceof NotFoundError) throw error;
    if (error.code === 'FAILED_PRECONDITION') {
      throw new IndexError(`Index required for ${this.collectionName}.${operation}: ${error.message}`);
    }
    logger.error('BaseRepository', `Error in ${operation} for ${this.collectionName}`, error);
    throw new FirestoreError(`Database error in ${this.collectionName}.${operation}`, error.message);
  }
}
