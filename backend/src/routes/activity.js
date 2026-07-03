import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as activityController from '../controllers/activityController.js';

const router = express.Router();

router.post('/api/activities', verifyToken, requirePermission(PERMISSIONS.MANAGE_ACTIVITIES), activityController.create);
router.get('/api/activities', verifyToken, requirePermission(PERMISSIONS.VIEW_ACTIVITIES), activityController.list);
router.get('/api/activities/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_ACTIVITIES), activityController.getById);
router.put('/api/activities/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_ACTIVITIES), activityController.update);
router.delete('/api/activities/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_ACTIVITIES), activityController.remove);

export default router;
