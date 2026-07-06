import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as reportController from '../controllers/reportController.js';

const router = express.Router();

router.post('/', verifyToken, reportController.generate);
router.get('/', verifyToken, reportController.list);
router.get('/:reportId', verifyToken, reportController.getById);
router.delete('/:reportId', verifyToken, reportController.remove);
router.get('/:reportId/export', verifyToken, reportController.export_report);

export default router;
