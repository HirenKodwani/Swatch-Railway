import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as premisesFormController from '../controllers/premisesFormController.js';

const router = express.Router();

router.post('/', verifyToken, premisesFormController.create);
router.get('/', verifyToken, premisesFormController.list);
router.get('/submitted', verifyToken, premisesFormController.submitted);
router.get('/:formId', verifyToken, premisesFormController.getById);
router.put('/:formId/approve-manpower', verifyToken, premisesFormController.approveManpower);
router.put('/:formId/scoring/draft', verifyToken, premisesFormController.saveScoringDraft);
router.put('/:formId/scoring', verifyToken, premisesFormController.submitScoring);
router.put('/:formId/accept-rating', verifyToken, premisesFormController.acceptRating);
router.put('/:formId/resubmit', verifyToken, premisesFormController.resubmit);
router.put('/:formId/reject', verifyToken, premisesFormController.reject);
router.get('/pending/scoring', verifyToken, premisesFormController.pendingScoring);

export default router;
