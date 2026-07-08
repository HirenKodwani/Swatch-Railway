import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as supervisorDailyLogController from '../controllers/supervisorDailyLogController.js';

const router = Router();

router.post('/api/supervisor-logs', verifyToken, requirePermission(PERMISSIONS.MANAGE_SUPERVISOR_LOGS), supervisorDailyLogController.createLog);
router.get('/api/supervisor-logs', verifyToken, requirePermission(PERMISSIONS.VIEW_SUPERVISOR_LOGS), supervisorDailyLogController.listLogs);
router.get('/api/supervisor-logs/handover', verifyToken, requirePermission(PERMISSIONS.VIEW_SUPERVISOR_LOGS), supervisorDailyLogController.getShiftHandover);
router.get('/api/supervisor-logs/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_SUPERVISOR_LOGS), supervisorDailyLogController.getLogById);
router.put('/api/supervisor-logs/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_SUPERVISOR_LOGS), supervisorDailyLogController.updateLog);
router.post('/api/supervisor-logs/:uid/submit', verifyToken, requirePermission(PERMISSIONS.MANAGE_SUPERVISOR_LOGS), supervisorDailyLogController.submitLog);
router.post('/api/supervisor-logs/:uid/acknowledge', verifyToken, requirePermission(PERMISSIONS.MANAGE_SUPERVISOR_LOGS), supervisorDailyLogController.acknowledgeLog);
router.post('/api/supervisor-logs/:uid/accept', verifyToken, requirePermission(PERMISSIONS.MANAGE_SUPERVISOR_LOGS), supervisorDailyLogController.acceptLog);
router.post('/api/supervisor-logs/:uid/reject', verifyToken, requirePermission(PERMISSIONS.MANAGE_SUPERVISOR_LOGS), supervisorDailyLogController.rejectLog);
router.post('/api/supervisor-logs/:uid/return', verifyToken, requirePermission(PERMISSIONS.MANAGE_SUPERVISOR_LOGS), supervisorDailyLogController.returnLog);

export default router;
