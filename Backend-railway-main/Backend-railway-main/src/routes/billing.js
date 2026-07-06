import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as billingController from '../controllers/billingController.js';

const router = express.Router();

router.post('/', verifyToken, billingController.create);
router.get('/', verifyToken, billingController.list);
router.get('/payments', verifyToken, billingController.getPayments);
router.post('/payments', verifyToken, billingController.recordPayment);
router.get('/:invoiceId', verifyToken, billingController.getById);
router.put('/:invoiceId', verifyToken, billingController.update);
router.delete('/:invoiceId', verifyToken, billingController.remove);
router.put('/:invoiceId/mark-paid', verifyToken, billingController.markPaid);

export default router;
