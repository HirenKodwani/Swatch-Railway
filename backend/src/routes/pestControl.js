import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as ctrl from '../controllers/pestControlController.js';

const router = express.Router();

router.post('/api/pest-control/chemicals', verifyToken, requirePermission(PERMISSIONS.MANAGE_PEST_CONTROL), ctrl.createChemical);
router.get('/api/pest-control/chemicals', verifyToken, requirePermission(PERMISSIONS.VIEW_PEST_CONTROL), ctrl.listChemicals);
router.post('/api/pest-control/chemicals/:uid/stock', verifyToken, requirePermission(PERMISSIONS.MANAGE_PEST_CONTROL), ctrl.stockChemical);
router.post('/api/pest-control/plans', verifyToken, requirePermission(PERMISSIONS.MANAGE_PEST_CONTROL), ctrl.createPlan);
router.get('/api/pest-control/plans', verifyToken, requirePermission(PERMISSIONS.VIEW_PEST_CONTROL), ctrl.listPlans);
router.get('/api/pest-control/plans/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_PEST_CONTROL), ctrl.getPlanById);
router.put('/api/pest-control/plans/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_PEST_CONTROL), ctrl.updatePlan);
router.post('/api/pest-control/plans/:uid/review', verifyToken, requirePermission(PERMISSIONS.MANAGE_PEST_CONTROL), ctrl.reviewPlan);
router.post('/api/pest-control/plans/:uid/treat', verifyToken, requirePermission(PERMISSIONS.MANAGE_PEST_CONTROL), ctrl.markTreated);
router.delete('/api/pest-control/plans/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_PEST_CONTROL), ctrl.deletePlan);
router.get('/api/pest-control/report', verifyToken, requirePermission(PERMISSIONS.VIEW_PEST_CONTROL), ctrl.report);

export default router;
