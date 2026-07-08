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
  if (role === 'STATION_MASTER' || role === 'AREA_MASTER') {
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

export function requireAreaAccess(req, res, next) {
  const role = (req.user?.role || '').toUpperCase();
  if (role === 'PLATFORM_MASTER' || role === 'WORKER' || role === 'CLEANING_STAFF' || role === 'JANITOR') {
    const userAreaId = req.user.areaId;
    if (!userAreaId) {
      throw new ForbiddenError('No area assigned to your account');
    }
    const targetAreaId = req.params.areaId || req.body.areaId || req.query.areaId;
    if (targetAreaId && targetAreaId !== userAreaId) {
      throw new ForbiddenError('You can only access your assigned area');
    }
  }
  next();
}

export function requireDashboardLevelAccess(level) {
  return (req, res, next) => {
    const role = (req.user?.role || '').toUpperCase();
    switch (level) {
      case 'admin':
        if (!['SUPER_ADMIN', 'ADMIN', 'RAILWAY_ADMIN', 'COMPANY_MASTER', 'RAILWAY_MASTER'].includes(role)) {
          throw new ForbiddenError('Admin dashboard access requires admin privileges');
        }
        break;
      case 'zone':
        if (!['SUPER_ADMIN', 'ADMIN', 'RAILWAY_ADMIN', 'COMPANY_MASTER', 'RAILWAY_MASTER', 'STATION_MASTER', 'AREA_MASTER'].includes(role)) {
          throw new ForbiddenError('Zone dashboard access requires zone-level privileges');
        }
        break;
      case 'station':
        if (!['SUPER_ADMIN', 'ADMIN', 'RAILWAY_ADMIN', 'COMPANY_MASTER', 'RAILWAY_MASTER', 'STATION_MASTER', 'AREA_MASTER'].includes(role)) {
          throw new ForbiddenError('Station dashboard access requires station-level privileges');
        }
        break;
      case 'platform':
        if (!['SUPER_ADMIN', 'ADMIN', 'RAILWAY_ADMIN', 'COMPANY_MASTER', 'RAILWAY_MASTER', 'STATION_MASTER', 'AREA_MASTER', 'PLATFORM_MASTER'].includes(role)) {
          throw new ForbiddenError('Platform dashboard access requires platform-level privileges');
        }
        break;
      case 'area':
        if (!['SUPER_ADMIN', 'ADMIN', 'RAILWAY_ADMIN', 'COMPANY_MASTER', 'RAILWAY_MASTER', 'STATION_MASTER', 'AREA_MASTER', 'PLATFORM_MASTER', 'WORKER', 'JANITOR'].includes(role)) {
          throw new ForbiddenError('Area dashboard access requires area-level privileges');
        }
        break;
    }
    next();
  };
}
