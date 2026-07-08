import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import notificationController from '../controllers/notificationController.js';

const router = Router();

router.get('/api/notifications', verifyToken, notificationController.getNotifications);
router.post('/api/notifications/:uid/read', verifyToken, notificationController.markAsRead);
router.post('/api/notifications/read-all', verifyToken, notificationController.markAllAsRead);
router.get('/api/notifications/unread-count', verifyToken, notificationController.getUnreadCount);

export default router;
