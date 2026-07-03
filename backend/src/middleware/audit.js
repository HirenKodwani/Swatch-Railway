import { db } from '../database/index.js';

export function auditLog(action, entityType, getEntityId, getOldValue, getNewValue) {
  return async (req, res, next) => {
    const originalJson = res.json.bind(res);
    res.json = function (body) {
      const actor = req.user || { uid: 'anonymous', role: 'anonymous', fullName: 'anonymous' };
      const entityId = typeof getEntityId === 'function' ? getEntityId(req, body) : (getEntityId || req.params?.uid || 'unknown');
      const oldValue = typeof getOldValue === 'function' ? getOldValue(req) : undefined;
      const newValue = typeof getNewValue === 'function' ? getNewValue(req, body) : undefined;

      const entry = {
        action,
        entityType,
        entityId,
        actorId: actor.uid,
        actorName: actor.fullName || actor.name || 'Unknown',
        actorRole: actor.role,
        ipAddress: req.ip || req.headers['x-forwarded-for'] || req.connection?.remoteAddress || 'unknown',
        userAgent: req.headers['user-agent'] || 'unknown',
        method: req.method,
        path: req.originalUrl,
        statusCode: res.statusCode,
        timestamp: new Date().toISOString()
      };
      if (oldValue !== undefined) entry.oldValue = oldValue;
      if (newValue !== undefined) entry.newValue = newValue;

      db.collection('audit_logs').add(entry).catch(() => {});
      return originalJson(body);
    };
    next();
  };
}
