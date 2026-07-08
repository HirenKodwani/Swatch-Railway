import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as ctsFormController from '../controllers/ctsFormController.js';

const router = express.Router();

router.post('/', verifyToken, ctsFormController.create);
router.get('/', verifyToken, ctsFormController.list);
router.get('/:formId', verifyToken, ctsFormController.getById);
router.put('/:formId/approve-manpower', verifyToken, ctsFormController.approveManpower);
router.put('/:formId/reject', verifyToken, ctsFormController.reject);
router.put('/:formId/scoring', verifyToken, ctsFormController.submitScoring);
router.put('/:formId/accept-rating', verifyToken, ctsFormController.acceptRating);
router.put('/:formId/resubmit', verifyToken, ctsFormController.resubmit);
router.post('/emergency-task', verifyToken, ctsFormController.createEmergencyTask);

export default router;
