import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as areaAssignmentController from '../controllers/areaAssignmentController.js';

const router = Router();

router.post('/api/area-assignments', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREA_ASSIGNMENTS), areaAssignmentController.create);
router.get('/api/area-assignments', verifyToken, requirePermission(PERMISSIONS.VIEW_AREA_ASSIGNMENTS), areaAssignmentController.list);
router.get('/api/area-assignments/area/:areaId', verifyToken, requirePermission(PERMISSIONS.VIEW_AREA_ASSIGNMENTS), areaAssignmentController.getAreaWorkers);
router.get('/api/area-assignments/worker/:workerId', verifyToken, requirePermission(PERMISSIONS.VIEW_AREA_ASSIGNMENTS), areaAssignmentController.getWorkerAreas);
router.put('/api/area-assignments/:id', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREA_ASSIGNMENTS), areaAssignmentController.update);
router.put('/api/area-assignments/:id/deactivate', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREA_ASSIGNMENTS), areaAssignmentController.remove);
router.delete('/api/area-assignments/:id', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREA_ASSIGNMENTS), areaAssignmentController.remove);
router.post('/api/area-assignments/bulk', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREA_ASSIGNMENTS), areaAssignmentController.bulkAssign);

export default router;
