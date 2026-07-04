import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as ctrl from '../controllers/garbageController.js';

const router = express.Router();

router.post('/api/garbage/waste-types', verifyToken, requirePermission(PERMISSIONS.MANAGE_GARBAGE), ctrl.createWasteType);
router.get('/api/garbage/waste-types', verifyToken, requirePermission(PERMISSIONS.VIEW_GARBAGE), ctrl.listWasteTypes);
router.post('/api/garbage/collections', verifyToken, requirePermission(PERMISSIONS.MANAGE_GARBAGE), ctrl.record);
router.get('/api/garbage/collections', verifyToken, requirePermission(PERMISSIONS.VIEW_GARBAGE), ctrl.list);
router.get('/api/garbage/collections/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_GARBAGE), ctrl.getById);
router.put('/api/garbage/collections/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_GARBAGE), ctrl.update);
router.post('/api/garbage/collections/:uid/verify', verifyToken, requirePermission(PERMISSIONS.MANAGE_GARBAGE), ctrl.verify);
router.post('/api/garbage/collections/:uid/approve', verifyToken, requirePermission(PERMISSIONS.MANAGE_GARBAGE), ctrl.approve);
router.post('/api/garbage/collections/:uid/dispose', verifyToken, requirePermission(PERMISSIONS.MANAGE_GARBAGE), ctrl.markDisposed);
router.post('/api/garbage/collections/:uid/reject', verifyToken, requirePermission(PERMISSIONS.MANAGE_GARBAGE), ctrl.rejectCollection);
router.get('/api/garbage/report', verifyToken, requirePermission(PERMISSIONS.VIEW_GARBAGE), ctrl.report);

export default router;
