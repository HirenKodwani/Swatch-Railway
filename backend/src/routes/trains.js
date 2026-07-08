import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import trainController from '../controllers/trainController.js';

const router = Router();

router.post('/api/trains', verifyToken, trainController.createTrain);
router.put('/api/trains/:uid', verifyToken, trainController.updateTrain);
router.get('/api/trains', verifyToken, trainController.getTrains);
router.get('/api/trains/:uid', verifyToken, trainController.getTrainByUid);
router.get('/api/trains/number/:trainNo', verifyToken, trainController.getTrainByNumber);
router.get('/api/train-pairs/train/:trainId', verifyToken, trainController.getTrainPairs);
router.post('/api/trains/:trainId/generate-schedule', verifyToken, trainController.generateSchedule);

export default router;
