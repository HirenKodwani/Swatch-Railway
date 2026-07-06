import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as dashboardController from '../controllers/dashboardController.js';

const router = express.Router();

router.get('/stats', verifyToken, dashboardController.stats);
router.get('/railway-dashboard-stats', verifyToken, dashboardController.railwayDashboardStats);

export default router;
