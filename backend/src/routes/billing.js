import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as billingController from '../controllers/billingController.js';

const router = express.Router();

router.post('/config', verifyToken, billingController.createConfig);
router.get('/config', verifyToken, billingController.listConfig);
router.get('/config/:contractId', verifyToken, billingController.getConfigByContract);
router.post('/generate', verifyToken, billingController.generateReport);
router.get('/reports', verifyToken, billingController.listReports);
router.get('/reports/:uid', verifyToken, billingController.getReportById);
router.post('/approve/:uid', verifyToken, billingController.approveReport);
router.post('/reject/:uid', verifyToken, billingController.rejectReport);
router.get('/dashboard', verifyToken, billingController.dashboard);
router.post('/generate-invoice/:uid', verifyToken, billingController.generateInvoice);
router.get('/contractor', verifyToken, billingController.contractorReports);
router.get('/supervisor', verifyToken, billingController.supervisorReports);
router.get('/invoice-pdf/:uid', verifyToken, billingController.getInvoicePdf);

export default router;
