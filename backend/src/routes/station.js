import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { createStationSchema } from '../validations/schemas.js';
import * as stationController from '../controllers/stationController.js';

const router = express.Router();

router.get('/', verifyToken, stationController.list);
router.get('/search', verifyToken, stationController.search);
router.post('/', verifyToken, validate(createStationSchema), stationController.create);
router.get('/division/:division', verifyToken, stationController.getByDivision);
router.get('/:stationId', verifyToken, stationController.getById);
router.put('/:stationId', verifyToken, stationController.update);
router.delete('/:stationId', verifyToken, stationController.remove);

export default router;
