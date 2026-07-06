import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as obhsController from '../controllers/obhsController.js';

const router = express.Router();

router.post('/', verifyToken, obhsController.submit);
router.get('/', verifyToken, obhsController.list);
router.get('/counts', verifyToken, obhsController.getStatusCounts);
router.get('/:obhsId', verifyToken, obhsController.getById);
router.put('/:obhsId', verifyToken, obhsController.update);
router.put('/:obhsId/approve', verifyToken, obhsController.approve);

export default router;
