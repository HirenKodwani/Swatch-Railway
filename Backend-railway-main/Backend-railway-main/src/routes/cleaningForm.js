import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as cleaningFormController from '../controllers/cleaningFormController.js';

const router = express.Router();

router.post('/', verifyToken, cleaningFormController.create);
router.get('/', verifyToken, cleaningFormController.list);
router.get('/dashboard/data', verifyToken, cleaningFormController.dashboard);
router.get('/report/:uid', verifyToken, cleaningFormController.report);
router.get('/:uid', verifyToken, cleaningFormController.getById);
router.put('/:uid/draft', verifyToken, cleaningFormController.saveDraft);
router.put('/:uid/submit', verifyToken, cleaningFormController.submit);
router.put('/:uid/approve', verifyToken, cleaningFormController.approve);
router.put('/:uid/reject', verifyToken, cleaningFormController.reject);
router.put('/:uid/score', verifyToken, cleaningFormController.score);
router.put('/:uid/acknowledge', verifyToken, cleaningFormController.acknowledge);
router.put('/:uid/auto-approve', verifyToken, cleaningFormController.autoApprove);
router.put('/:uid/lock', verifyToken, cleaningFormController.lock);

export default router;
