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
router.post('/submit/:uid', verifyToken, cleaningFormController.submit);
router.post('/approve/:uid', verifyToken, cleaningFormController.approve);
router.post('/reject/:uid', verifyToken, cleaningFormController.reject);
router.post('/score/:uid', verifyToken, cleaningFormController.score);
router.post('/acknowledge/:uid', verifyToken, cleaningFormController.acknowledge);
router.post('/auto-approve/:uid', verifyToken, cleaningFormController.autoApprove);
router.post('/lock/:uid', verifyToken, cleaningFormController.lock);

export default router;
