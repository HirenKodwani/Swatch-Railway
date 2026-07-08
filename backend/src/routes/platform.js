import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { validate } from '../middleware/validate.js';
import { createPlatformSchema } from '../validations/schemas.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as platformController from '../controllers/platformController.js';

const router = express.Router();

router.post('/api/platforms', verifyToken, requirePermission(PERMISSIONS.MANAGE_PLATFORMS), validate(createPlatformSchema), platformController.create);
router.get('/api/platforms', verifyToken, requirePermission(PERMISSIONS.VIEW_PLATFORMS), platformController.list);
router.get('/api/platforms/by-station/:stationId', verifyToken, requirePermission(PERMISSIONS.VIEW_PLATFORMS), platformController.getByStation);
router.get('/api/platforms/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_PLATFORMS), platformController.getById);
router.put('/api/platforms/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_PLATFORMS), platformController.update);
router.delete('/api/platforms/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_PLATFORMS), platformController.remove);

export default router;
