import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as frequencyController from '../controllers/frequencyController.js';

const router = express.Router();

router.post('/api/frequencies', verifyToken, requirePermission(PERMISSIONS.MANAGE_FREQUENCIES), frequencyController.create);
router.get('/api/frequencies', verifyToken, requirePermission(PERMISSIONS.VIEW_FREQUENCIES), frequencyController.list);
router.get('/api/frequencies/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_FREQUENCIES), frequencyController.getById);
router.put('/api/frequencies/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_FREQUENCIES), frequencyController.update);
router.delete('/api/frequencies/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_FREQUENCIES), frequencyController.remove);

// Frequency calculation and task generation endpoints
router.post('/api/frequencies/calculate-tasks', verifyToken, requirePermission(PERMISSIONS.CALCULATE_FREQUENCY), frequencyController.calculateTasksFromFrequency);
router.post('/api/frequencies/generate-tasks', verifyToken, requirePermission(PERMISSIONS.GENERATE_TASKS), frequencyController.generateTasksFromFrequency);
router.get('/api/frequencies/schedule', verifyToken, requirePermission(PERMISSIONS.VIEW_FREQUENCIES), frequencyController.getFrequencySchedule);

export default router;
