import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as executionController from '../controllers/executionController.js';

const router = express.Router();

router.post('/api/execution-plans', verifyToken, requirePermission(PERMISSIONS.MANAGE_EXECUTION), executionController.createPlan);
router.get('/api/execution-plans', verifyToken, requirePermission(PERMISSIONS.VIEW_EXECUTION), executionController.listPlans);
router.get('/api/execution-plans/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_EXECUTION), executionController.getPlanById);
router.put('/api/execution-plans/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_EXECUTION), executionController.updatePlan);
router.post('/api/execution-plans/:uid/submit', verifyToken, requirePermission(PERMISSIONS.MANAGE_EXECUTION), executionController.submitPlan);
router.post('/api/execution-plans/:uid/approve', verifyToken, requirePermission(PERMISSIONS.APPROVE_EXECUTION), executionController.approvePlan);
router.post('/api/execution-plans/:uid/reject', verifyToken, requirePermission(PERMISSIONS.APPROVE_EXECUTION), executionController.rejectPlan);
router.delete('/api/execution-plans/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_EXECUTION), executionController.deletePlan);
router.post('/api/execution-logs', verifyToken, requirePermission(PERMISSIONS.MANAGE_EXECUTION), executionController.createLog);
router.get('/api/execution-logs', verifyToken, requirePermission(PERMISSIONS.VIEW_EXECUTION), executionController.listLogs);
router.get('/api/execution-logs/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_EXECUTION), executionController.getLogById);

export default router;
