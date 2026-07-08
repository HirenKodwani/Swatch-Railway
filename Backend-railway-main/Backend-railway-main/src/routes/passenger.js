import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as passengerController from '../controllers/passengerController.js';

const router = express.Router();

router.post('/', verifyToken, passengerController.create);
router.get('/', verifyToken, passengerController.list);
router.get('/:passengerId', verifyToken, passengerController.getById);
router.put('/:passengerId', verifyToken, passengerController.update);
router.delete('/:passengerId', verifyToken, passengerController.remove);

export default router;
