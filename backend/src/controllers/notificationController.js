import { notificationService } from '../services/notificationService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const getNotifications = asyncHandler(async (req, res) => {
  const { limit, offset } = req.query;
  const result = await notificationService.getNotifications(
    req.user.uid,
    parseInt(limit) || 50,
    parseInt(offset) || 0
  );
  res.status(200).json(result);
});

export const markAsRead = asyncHandler(async (req, res) => {
  const result = await notificationService.markAsRead(req.params.uid, req.user.uid);
  res.status(200).json(result);
});

export const markAllAsRead = asyncHandler(async (req, res) => {
  const result = await notificationService.markAllAsRead(req.user.uid);
  res.status(200).json(result);
});

export const getUnreadCount = asyncHandler(async (req, res) => {
  const result = await notificationService.getUnreadCount(req.user.uid);
  res.status(200).json(result);
});

export default { getNotifications, markAsRead, markAllAsRead, getUnreadCount };
