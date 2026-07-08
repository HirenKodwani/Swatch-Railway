import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { validate } from '../middleware/validate.js';
import { createMachineSchema } from '../validations/schemas.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as machineController from '../controllers/machineController.js';

const router = express.Router();

router.post('/api/machines', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), validate(createMachineSchema), machineController.create);
router.get('/api/machines', verifyToken, requirePermission(PERMISSIONS.VIEW_MACHINES), machineController.list);
router.get('/api/machines/station/:stationId', verifyToken, requirePermission(PERMISSIONS.VIEW_MACHINES), machineController.listByStation);
router.get('/api/machines/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_MACHINES), machineController.getById);
router.put('/api/machines/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), machineController.update);
router.delete('/api/machines/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), machineController.remove);
router.post('/api/machines/deploy', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), machineController.deploy);
router.post('/api/machines/deployments/:uid/return', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), machineController.returnMachine);
router.get('/api/machines/deployments', verifyToken, requirePermission(PERMISSIONS.VIEW_MACHINES), machineController.listDeployments);
router.get('/api/machines/downtime', verifyToken, requirePermission(PERMISSIONS.VIEW_MACHINES), machineController.listDowntime);
router.post('/api/machines/downtime', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), machineController.logDowntime);
router.post('/api/machines/downtime/:uid/resolve', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), machineController.resolveDowntime);
router.get('/api/machines/downtime/report', verifyToken, requirePermission(PERMISSIONS.VIEW_MACHINES), machineController.downtimeReport);
router.post('/api/machines/maintenance', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), machineController.scheduleMaintenance);
router.post('/api/machines/maintenance/:uid/complete', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), machineController.completeMaintenance);
router.get('/api/machines/maintenance', verifyToken, requirePermission(PERMISSIONS.VIEW_MACHINES), machineController.listMaintenance);
router.post('/api/machines/:uid/replacement/request', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), machineController.requestReplacement);
router.post('/api/machines/replacement/:uid/approve', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), machineController.approveReplacement);
router.get('/api/machines/replacement/requests', verifyToken, requirePermission(PERMISSIONS.VIEW_MACHINES), machineController.listReplacementRequests);

export default router;
