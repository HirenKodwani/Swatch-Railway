import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import logger from '../logger/index.js';

class AuditService {
  async getAuditLogs(filters = {}) {
    const { action, actorId, targetId, startDate, endDate, limit = 50, offset = 0 } = filters;
    const maxLimit = Math.min(parseInt(limit), 200);

    let query = db.collection('audit_logs').orderBy('createdAt', 'desc');
    if (action) query = query.where('action', '==', action);
    if (actorId) query = query.where('actorId', '==', actorId);
    if (targetId) query = query.where('targetId', '==', targetId);

    const snapshot = await query.limit(maxLimit).get();
    const logs = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      logs.push({
        ...data,
        createdAt: data.createdAt?.toDate?.()?.toISOString() || data.createdAt || null,
      });
    });

    return { count: logs.length, logs };
  }

  async getAuditStats(filters = {}) {
    const snapshot = await db.collection('audit_logs').limit(200).get();
    const stats = {};
    snapshot.forEach(doc => {
      const d = doc.data();
      stats[d.action] = (stats[d.action] || 0) + 1;
    });

    let total = 0;
    for (const key of Object.keys(stats)) {
      total += stats[key];
    }

    return { stats, total };
  }

  async getEvidenceAudit(filters = {}) {
    const { evidenceId, action, userId, limit = 50 } = filters;
    let query = db.collection('audit_evidence').orderBy('timestamp', 'desc').limit(parseInt(limit));

    if (evidenceId) query = query.where('evidenceId', '==', evidenceId);
    if (action) query = query.where('action', '==', action);
    if (userId) query = query.where('userId', '==', userId);

    const snap = await query.get();
    const logs = snap.docs.map(d => ({ id: d.id, ...d.data() }));

    return { success: true, count: logs.length, logs };
  }

  async logAudit(action, actorId, actorName, targetId, targetType, details = null, changes = null) {
    const ref = db.collection('audit_logs').doc();
    const entry = {
      uid: ref.id,
      action,
      actorId,
      actorName,
      targetId,
      targetType,
      details,
      changes,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await ref.set(entry);
    logger.info('AuditService', `Audit log: ${action}`, { actorId, targetId, targetType });
    return { uid: ref.id, ...entry, createdAt: new Date().toISOString() };
  }
}

export const auditService = new AuditService();
