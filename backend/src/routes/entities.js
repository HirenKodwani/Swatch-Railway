import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import entityController from '../controllers/entityController.js';

const router = Router();

router.post('/api/contractors', verifyToken, requirePermission(PERMISSIONS.CREATE_ENTITY), entityController.createEntity);
router.put('/api/contractors/:uid', verifyToken, requirePermission(PERMISSIONS.UPDATE_ENTITY), entityController.updateEntity);
router.get('/api/contractors', verifyToken, requirePermission(PERMISSIONS.VIEW_ENTITIES), entityController.getEntities);
router.post('/api/master/approveContractor/:uid', verifyToken, requirePermission(PERMISSIONS.APPROVE_ENTITY), entityController.approveEntity);
router.post('/api/master/rejectContractor/:uid', verifyToken, requirePermission(PERMISSIONS.REJECT_ENTITY), entityController.rejectEntity);
router.post('/api/admin/suspendContractor/:uid', verifyToken, requirePermission(PERMISSIONS.SUSPEND_ENTITY), entityController.suspendEntity);
router.get('/api/contractors/details/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_ENTITIES), entityController.getEntityDetails);

export default router;
