import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as passengerController from '../controllers/passengerController.js';

const router = express.Router();

router.post('/', verifyToken, passengerController.create);
router.get('/', verifyToken, passengerController.list);
router.get('/tasks', verifyToken, passengerController.getTasks);
router.get('/:passengerId', verifyToken, passengerController.getById);
router.put('/:passengerId', verifyToken, passengerController.update);
router.delete('/:passengerId', verifyToken, passengerController.remove);

router.post('/send-otp', passengerController.sendOtp);
router.post('/verify-otp', passengerController.verifyOtp);
router.post('/create-task', passengerController.createTask);
router.get('/train/:trainNo/coaches', passengerController.getTrainCoaches);
router.post('/create-emergency-task', verifyToken, passengerController.createEmergencyTask);
router.post('/submit-feedback', passengerController.submitFeedback);

export default router;
