import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as inspectionController from '../controllers/inspectionController.js';

const router = express.Router();

router.post('/api/inspections', verifyToken, requirePermission(PERMISSIONS.MANAGE_INSPECTIONS), inspectionController.create);
router.get('/api/inspections', verifyToken, requirePermission(PERMISSIONS.VIEW_INSPECTIONS), inspectionController.list);
router.post('/api/inspections/:uid/start', verifyToken, requirePermission(PERMISSIONS.MANAGE_INSPECTIONS), inspectionController.start);
router.post('/api/inspections/:uid/ratings', verifyToken, requirePermission(PERMISSIONS.SCORE_INSPECTION), inspectionController.submitRatings);
router.post('/api/inspections/:uid/approve', verifyToken, requirePermission(PERMISSIONS.APPROVE_INSPECTION), inspectionController.approve);
router.post('/api/inspections/:uid/reject', verifyToken, requirePermission(PERMISSIONS.APPROVE_INSPECTION), inspectionController.reject);
router.post('/api/inspections/:uid/resubmit', verifyToken, requirePermission(PERMISSIONS.SCORE_INSPECTION), inspectionController.resubmit);
router.get('/api/inspections/score-summary/:stationId', verifyToken, requirePermission(PERMISSIONS.VIEW_INSPECTIONS), inspectionController.scoreSummary);
router.get('/api/inspections/templates', verifyToken, requirePermission(PERMISSIONS.VIEW_INSPECTIONS), inspectionController.listTemplates);
router.post('/api/inspections/templates', verifyToken, requirePermission(PERMISSIONS.MANAGE_INSPECTIONS), inspectionController.createTemplate);
router.get('/api/inspections/templates/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_INSPECTIONS), inspectionController.getTemplateById);
router.put('/api/inspections/templates/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_INSPECTIONS), inspectionController.updateTemplate);
router.delete('/api/inspections/templates/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_INSPECTIONS), inspectionController.deleteTemplate);
router.get('/api/inspections/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_INSPECTIONS), inspectionController.getById);
router.put('/api/inspections/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_INSPECTIONS), inspectionController.update);
router.delete('/api/inspections/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_INSPECTIONS), inspectionController.remove);
router.post('/api/inspections/:uid/deficiencies', verifyToken, requirePermission(PERMISSIONS.MANAGE_INSPECTIONS), inspectionController.addDeficiency);
router.post('/api/inspections/:uid/deficiencies/:defId/close', verifyToken, requirePermission(PERMISSIONS.MANAGE_INSPECTIONS), inspectionController.closeDeficiency);
router.post('/api/inspections/:uid/deficiencies/:defId/verify', verifyToken, requirePermission(PERMISSIONS.APPROVE_INSPECTION), inspectionController.verifyDeficiency);

export default router;
