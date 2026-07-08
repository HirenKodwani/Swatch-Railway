import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as analyticsController from '../controllers/obhsAnalyticsController.js';

const router = Router();

router.get('/api/analytics/janitor-performance', verifyToken, analyticsController.getJanitorPerformance);
router.get('/api/analytics/coach-cleanliness', verifyToken, analyticsController.getCoachCleanliness);
router.get('/api/analytics/complaint-resolution', verifyToken, (req, res, next) => {
  req.params = { runInstanceId: req.query.runInstanceId || '' };
  analyticsController.getComprehensiveReport(req, res, next);
});
router.get('/api/obhs/analytics/attendance-compliance', verifyToken, analyticsController.getAttendanceCompliance);
router.get('/api/obhs/analytics/task-completion', verifyToken, analyticsController.getTaskCompletion);
router.get('/api/analytics/passenger-rating-trend', verifyToken, analyticsController.getPassengerRatingTrend);
router.get('/api/analytics/penalty-risk', verifyToken, analyticsController.getPenaltyRisk);

export default router;
