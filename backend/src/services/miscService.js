import { db } from '../database/index.js';
import * as evidence from '../../evidence_manager.js';
import { NotFoundError, ValidationError } from '../errors/index.js';

class MiscService {
  async getAuditLogs(queryParams) {
    const { entityType, entityId, actorId, action, limit: limitParam } = queryParams;
    let query = db.collection('audit_logs').orderBy('timestamp', 'desc');
    if (entityType) query = query.where('entityType', '==', entityType);
    if (entityId) query = query.where('entityId', '==', entityId);
    if (actorId) query = query.where('actorId', '==', actorId);
    if (action) query = query.where('action', '==', action);
    const snapshot = await query.limit(Number(limitParam) || 100).get();
    const logs = [];
    snapshot.forEach(doc => logs.push(doc.data()));
    return { count: logs.length, logs };
  }

  async getAuditLogStats() {
    const snapshot = await db.collection('audit_logs').limit(200).get();
    const stats = { totalLogs: snapshot.size };
    const actionCounts = {};
    snapshot.forEach(doc => {
      const action = doc.data().action || 'UNKNOWN';
      actionCounts[action] = (actionCounts[action] || 0) + 1;
    });
    stats.actionBreakdown = actionCounts;
    return stats;
  }

  async getEvidenceAuditLogs() {
    return { message: 'Evidence audit logs' };
  }

  async performBackup(type, user) {
    const result = await evidence.performBackup(db, type);

    await evidence.logAudit(db, 'BACKUP_PERFORMED', {
      userId: user.uid, userName: user.fullName,
      userRole: user.role,
      details: `Backup type: ${type}, records: ${JSON.stringify(result.recordCounts)}`
    });

    return { success: true, ...result };
  }

  async getBackupLogs() {
    return { message: 'Logs backup endpoint' };
  }

  async getNotifications(user) {
    const { uid, entityId } = user;
    let query = db.collection('notifications').orderBy('createdAt', 'desc').limit(50);
    if (entityId) query = query.where('entityId', '==', entityId);
    else query = query.where('userId', '==', uid);
    const snapshot = await query.get();
    const notifications = [];
    snapshot.forEach(doc => notifications.push(doc.data()));
    return { count: notifications.length, notifications };
  }

  async markNotificationRead(uid) {
    await db.collection('notifications').doc(uid).update({ read: true });
    return { message: 'Marked as read' };
  }

  async markAllNotificationsRead(user) {
    const { uid, entityId } = user;
    let query = db.collection('notifications').where('read', '==', false);
    if (entityId) query = query.where('entityId', '==', entityId);
    else query = query.where('userId', '==', uid);
    const snapshot = await query.limit(200).get();
    const batch = db.batch();
    snapshot.forEach(doc => batch.update(doc.ref, { read: true }));
    await batch.commit();
    return { message: `${snapshot.size} marked as read` };
  }

  async getUnreadCount(user) {
    const { uid, entityId } = user;
    let query = db.collection('notifications').where('read', '==', false);
    if (entityId) query = query.where('entityId', '==', entityId);
    else query = query.where('userId', '==', uid);
    const snapshot = await query.limit(200).get();
    return { count: snapshot.size };
  }

  async getStorageAnalytics() {
    return { totalSize: 0, totalFiles: 0 };
  }

  async getDailyUploadCount() {
    return { count: 0 };
  }

  async getStoragePerContractor() {
    return { data: [] };
  }

  async getStoragePerTrain() {
    return { data: [] };
  }

  async getDivisions() {
    const snapshot = await db.collection('divisions').limit(200).get();
    const divisions = [];
    snapshot.forEach(doc => divisions.push(doc.data()));
    return { count: divisions.length, divisions };
  }

  async createDivision(body) {
    const { name, code, zone } = body;
    const ref = db.collection('divisions').doc();
    await ref.set({ uid: ref.id, name, code, zone, createdAt: new Date().toISOString() });
    return { message: 'Division created', uid: ref.id };
  }

  async updateDivision(id, body) {
    await db.collection('divisions').doc(id).update(body);
    return { message: 'Division updated' };
  }

  async getDivision(id) {
    const doc = await db.collection('divisions').doc(id).get();
    if (!doc.exists) throw new NotFoundError('Division not found');
    return { division: doc.data() };
  }

  async deleteDivision(id) {
    const ref = db.collection('divisions').doc(id);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Division not found');
    await ref.delete();
    return { message: 'Division deleted' };
  }

  async updateProfile(uid, body) {
    const { fullName, designation, mobile } = body;
    const ref = db.collection('users').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('User not found');
    const updateData = {};
    if (fullName !== undefined) updateData.fullName = fullName;
    if (designation !== undefined) updateData.designation = designation;
    if (mobile !== undefined) {
      if (!/^\d{10}$/.test(mobile)) {
        throw new ValidationError('Invalid mobile number. Must be 10 digits.');
      }
      updateData.mobile = mobile;
    }
    if (Object.keys(updateData).length === 0) {
      throw new ValidationError('No fields to update.');
    }
    updateData.updatedAt = new Date().toISOString();
    updateData.updatedBy = uid;
    await ref.update(updateData);
    const updated = await ref.get();
    return { message: 'Profile updated successfully', user: updated.data() };
  }
}

export const miscService = new MiscService();
