import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as scorecardController from '../controllers/scorecardController.js';

const router = express.Router();

router.post('/api/scorecards/daily', verifyToken, requirePermission(PERMISSIONS.MANAGE_SCORECARDS), scorecardController.createDaily);
router.get('/api/scorecards/daily', verifyToken, requirePermission(PERMISSIONS.VIEW_SCORECARDS), scorecardController.list);
router.get('/api/scorecards/monthly/:stationId', verifyToken, requirePermission(PERMISSIONS.VIEW_SCORECARDS), scorecardController.monthly);
router.get('/api/scorecards/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_SCORECARDS), scorecardController.getById);
router.put('/api/scorecards/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_SCORECARDS), scorecardController.update);
router.post('/api/scorecards/:uid/submit', verifyToken, requirePermission(PERMISSIONS.MANAGE_SCORECARDS), scorecardController.submit);
router.post('/api/scorecards/:uid/approve', verifyToken, requirePermission(PERMISSIONS.APPROVE_SCORECARDS), scorecardController.approve);
router.post('/api/scorecards/:uid/reject', verifyToken, requirePermission(PERMISSIONS.APPROVE_SCORECARDS), scorecardController.reject);
router.post('/api/scorecards/auto-generate', verifyToken, requirePermission(PERMISSIONS.MANAGE_SCORECARDS), scorecardController.autoGenerate);
router.delete('/api/scorecards/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_SCORECARDS), scorecardController.remove);

export default router;
