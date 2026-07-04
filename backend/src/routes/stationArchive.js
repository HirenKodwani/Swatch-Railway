import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as stationArchiveController from '../controllers/stationArchiveController.js';

const router = Router();

router.post('/api/station-archives/trigger', verifyToken, stationArchiveController.triggerArchive);
router.get('/api/station-archives', verifyToken, stationArchiveController.listArchives);
router.get('/api/station-archives/:uid', verifyToken, stationArchiveController.getArchiveById);
router.post('/api/station-archives/purge', verifyToken, stationArchiveController.purgeArchives);

export default router;
