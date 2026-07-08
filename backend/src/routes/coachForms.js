import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as coachFormController from '../controllers/coachFormController.js';

const router = express.Router();

router.post('/', verifyToken, coachFormController.create);
router.get('/', verifyToken, coachFormController.list);
router.get('/submitted', verifyToken, coachFormController.getSubmitted);
router.get('/pending/scoring', verifyToken, coachFormController.getPendingScoring);
router.get('/:formId', verifyToken, coachFormController.getById);
router.put('/:formId/approve-manpower', verifyToken, coachFormController.approveManpower);
router.put('/:formId/scoring/draft', verifyToken, coachFormController.saveScoringDraft);
router.put('/:formId/scoring', verifyToken, coachFormController.submitScoring);
router.put('/:formId/accept-rating', verifyToken, coachFormController.acceptRating);
router.put('/:formId/resubmit', verifyToken, coachFormController.resubmit);
router.put('/:formId/reject', verifyToken, coachFormController.reject);

export default router;
