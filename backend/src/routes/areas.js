import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission, requireAreaMasterAccess, requirePlatformMasterAccess, requireMasterAccess } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as areaController from '../controllers/areaController.js';

const router = Router();

router.post('/api/areas', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREAS), areaController.create);
router.get('/api/areas', verifyToken, requirePermission(PERMISSIONS.VIEW_AREAS), areaController.list);
router.get('/api/areas/by-station/:stationId', verifyToken, requirePermission(PERMISSIONS.VIEW_AREAS), areaController.getByStation);
router.get('/api/areas/by-platform/:stationId/:platformId', verifyToken, requirePermission(PERMISSIONS.VIEW_AREAS), areaController.getByPlatform);
router.get('/api/areas/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_AREAS), areaController.getById);
router.put('/api/areas/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREAS), areaController.update);
router.delete('/api/areas/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREAS), areaController.remove);

// Area Master specific endpoints
router.get('/api/areas/master/dashboard', verifyToken, requireAreaMasterAccess, areaController.getMasterDashboard);
router.get('/api/areas/master/workers', verifyToken, requireAreaMasterAccess, areaController.getAreaWorkers);
router.get('/api/areas/master/tasks', verifyToken, requireAreaMasterAccess, areaController.getAreaTasks);
router.get('/api/areas/master/reports', verifyToken, requireAreaMasterAccess, areaController.getAreaReports);
router.post('/api/areas/master/assign-worker', verifyToken, requireAreaMasterAccess, areaController.assignWorkerToArea);
router.delete('/api/areas/master/unassign-worker/:workerId', verifyToken, requireAreaMasterAccess, areaController.unassignWorkerFromArea);
router.post('/api/areas/master/assign-platform', verifyToken, requireAreaMasterAccess, areaController.assignPlatformToArea);
router.delete('/api/areas/master/unassign-platform/:platformId', verifyToken, requireAreaMasterAccess, areaController.unassignPlatformFromArea);
router.post('/api/areas/master/generate-tasks-from-frequency', verifyToken, requireAreaMasterAccess, areaController.generateTasksFromFrequency);

// Platform Master can also access area endpoints within their platform
router.get('/api/areas/platform/:platformId/areas', verifyToken, requirePlatformMasterAccess, areaController.getAreasByPlatform);

// Master access endpoints
router.get('/api/areas/station/:stationId/areas', verifyToken, requireMasterAccess('STATION_MASTER'), areaController.getAreasByStation);
router.get('/api/areas/company/:companyId/areas', verifyToken, requireMasterAccess('COMPANY_MASTER'), areaController.getAreasByCompany);

export default router;
