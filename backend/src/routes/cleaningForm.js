import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as cleaningFormController from '../controllers/cleaningFormController.js';

const router = express.Router();

router.post('/', verifyToken, cleaningFormController.create);
router.get('/', verifyToken, cleaningFormController.list);
router.get('/dashboard/data', verifyToken, cleaningFormController.dashboard);
router.get('/report/:uid', verifyToken, cleaningFormController.report);
router.get('/:uid', verifyToken, cleaningFormController.getById);
router.put('/save-draft/:uid', verifyToken, cleaningFormController.saveDraft);
router.put('/:uid/draft', verifyToken, cleaningFormController.saveDraft);

router.post('/submit/:uid', verifyToken, cleaningFormController.submit);
router.put('/:uid/submit', verifyToken, cleaningFormController.submit);

router.post('/approve/:uid', verifyToken, cleaningFormController.approve);
router.put('/:uid/approve', verifyToken, cleaningFormController.approve);

router.post('/reject/:uid', verifyToken, cleaningFormController.reject);
router.put('/:uid/reject', verifyToken, cleaningFormController.reject);

router.post('/score/:uid', verifyToken, cleaningFormController.score);
router.put('/:uid/score', verifyToken, cleaningFormController.score);

router.post('/acknowledge/:uid', verifyToken, cleaningFormController.acknowledge);
router.put('/:uid/acknowledge', verifyToken, cleaningFormController.acknowledge);

router.post('/auto-approve/:uid', verifyToken, cleaningFormController.autoApprove);
router.put('/:uid/auto-approve', verifyToken, cleaningFormController.autoApprove);

router.post('/lock/:uid', verifyToken, cleaningFormController.lock);
router.put('/:uid/lock', verifyToken, cleaningFormController.lock);

export default router;
