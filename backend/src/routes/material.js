import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { validate } from '../middleware/validate.js';
import { createMaterialSchema } from '../validations/schemas.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as materialController from '../controllers/materialController.js';

const router = express.Router();

router.post('/api/materials', verifyToken, requirePermission(PERMISSIONS.MANAGE_MATERIALS), validate(createMaterialSchema), materialController.create);
router.get('/api/materials', verifyToken, requirePermission(PERMISSIONS.VIEW_MATERIALS), materialController.list);
router.get('/api/materials/alerts', verifyToken, requirePermission(PERMISSIONS.VIEW_MATERIALS), materialController.getStockAlerts);
router.get('/api/materials/logs', verifyToken, requirePermission(PERMISSIONS.VIEW_MATERIALS), materialController.getLogs);
router.get('/api/materials/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_MATERIALS), materialController.getById);
router.put('/api/materials/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_MATERIALS), materialController.update);
router.delete('/api/materials/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_MATERIALS), materialController.remove);
router.post('/api/materials/:uid/issue', verifyToken, requirePermission(PERMISSIONS.MANAGE_MATERIALS), materialController.issue);
router.post('/api/materials/:uid/use', verifyToken, requirePermission(PERMISSIONS.MANAGE_MATERIALS), materialController.use);
router.post('/api/materials/:uid/receive', verifyToken, requirePermission(PERMISSIONS.MANAGE_MATERIALS), materialController.receive);

export default router;
