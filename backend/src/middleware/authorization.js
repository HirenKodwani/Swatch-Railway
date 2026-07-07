import { ForbiddenError } from '../errors/index.js';
import { ROLE_PERMISSIONS } from '../permissions/roles.js';

export function requirePermission(permission) {
  return (req, res, next) => {
    const role = (req.user?.role || '').toUpperCase();
    const normalizedRole = role.replace(/\s+/g, '_');
    const permissions = ROLE_PERMISSIONS[normalizedRole] || [];

    if (!permissions.includes(permission)) {
      throw new ForbiddenError(`Insufficient permissions. Required: ${permission}`);
    }
    next();
  };
}

export function requireRole(...allowedRoles) {
  return (req, res, next) => {
    const userRole = (req.user?.role || '').toUpperCase();
    const normalizedUserRole = userRole.replace(/\s+/g, '_');

    const allowed = allowedRoles.map(r => r.toUpperCase().replace(/\s+/g, '_'));

    if (!allowed.includes(normalizedUserRole)) {
      throw new ForbiddenError(`Access denied. Required role: ${allowedRoles.join(' or ')}`);
    }
    next();
  };
}

export function requireAnyRole(...allowedRoles) {
  return (req, res, next) => {
    const userRole = (req.user?.role || '').toLowerCase();

    const hasAccess = allowedRoles.some(role =>
      userRole.includes(role.toLowerCase())
    );

    if (!hasAccess) {
      throw new ForbiddenError('Access denied for your role');
    }
    next();
  };
}

export function requireEntityAccess(req, res, next) {
  const { userType, entityId: userEntityId } = req.user || {};
  const targetEntityId = req.params.uid || req.query.entityId || req.body.entityId;

  if (userType === 'contractor' && targetEntityId && targetEntityId !== userEntityId) {
    throw new ForbiddenError('You can only access your own company data');
  }
  next();
}

export function requireStationAccess(req, res, next) {
  const role = (req.user?.role || '').toUpperCase();
  if (role === 'STATION_MASTER') {
    const stationId = req.user.stationId;
    if (!stationId) {
      throw new ForbiddenError('No station assigned to your account');
    }
    const targetStationId = req.params.stationId || req.body.stationId || req.query.stationId;
    if (targetStationId && targetStationId !== stationId) {
      throw new ForbiddenError('You can only access your assigned station');
    }
  }
  next();
}

export function requirePlatformAccess(req, res, next) {
  const role = (req.user?.role || '').toUpperCase();
  if (role === 'PLATFORM_MASTER') {
    const areaId = req.user.areaId;
    if (!areaId) {
      throw new ForbiddenError('No platform/area assigned to your account');
    }
    const targetAreaId = req.params.areaId || req.body.areaId || req.query.areaId;
    if (targetAreaId && targetAreaId !== areaId) {
      throw new ForbiddenError('You can only access your assigned platform/area');
    }
  }
  next();
}
