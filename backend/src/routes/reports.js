import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as reportController from '../controllers/reportController.js';

const router = express.Router();

// New routes (defined first to avoid param conflicts)
router.post('/api/reports/generate', verifyToken, reportController.generateReport);
router.post('/api/reports/email', verifyToken, reportController.emailReport);
router.get('/api/reports/history', verifyToken, reportController.getReportHistory);
router.get('/api/reports/email-history', verifyToken, reportController.getEmailHistory);
router.post('/api/reports/generate/audit', verifyToken, reportController.generateAuditReport);
router.post('/api/reports/send-email', verifyToken, reportController.sendEmail);
router.post('/api/reports/generate/daily', verifyToken, reportController.generateDailyReport);
router.post('/api/reports/generate/weekly', verifyToken, reportController.generateWeeklyReport);
router.post('/api/reports/generate/monthly', verifyToken, reportController.generateMonthlyReport);
router.get('/api/reports/coach-data', verifyToken, reportController.getCoachData);
router.get('/api/reports/premises-data', verifyToken, reportController.getPremisesData);
router.get('/api/reports/cts-data', verifyToken, reportController.getCtsData);
router.get('/api/reports/cts-stats', verifyToken, reportController.getCtsStats);
router.get('/api/reports/coach-stats', verifyToken, reportController.getCoachStats);
router.get('/api/reports/coach-statistics', verifyToken, reportController.getCoachStats);
router.get('/api/reports/premises-stats', verifyToken, reportController.getPremisesStats);
router.get('/api/reports/premises-statistics', verifyToken, reportController.getPremisesStats);
router.get('/api/reports/train-performance', verifyToken, reportController.getTrainPerformance);
router.get('/api/billing/invoice-pdf/:uid', verifyToken, reportController.getInvoicePdf);

// Existing routes
router.post('/api/reports', verifyToken, reportController.generate);
router.get('/api/reports', verifyToken, reportController.list);
router.get('/api/reports/:reportId', verifyToken, reportController.getById);
router.delete('/api/reports/:reportId', verifyToken, reportController.remove);
router.get('/api/reports/:reportId/export', verifyToken, reportController.export_report);

export default router;
