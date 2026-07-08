import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as stationArchiveController from '../controllers/stationArchiveController.js';

const router = Router();

router.post('/api/station-archives/trigger', verifyToken, requirePermission(PERMISSIONS.MANAGE_ARCHIVES), stationArchiveController.triggerArchive);
router.get('/api/station-archives', verifyToken, requirePermission(PERMISSIONS.VIEW_ARCHIVES), stationArchiveController.listArchives);
router.get('/api/station-archives/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_ARCHIVES), stationArchiveController.getArchiveById);
router.post('/api/station-archives/purge', verifyToken, requirePermission(PERMISSIONS.MANAGE_ARCHIVES), stationArchiveController.purgeArchives);

export default router;
