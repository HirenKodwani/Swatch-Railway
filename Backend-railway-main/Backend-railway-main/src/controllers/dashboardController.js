import { dashboardService } from '../services/dashboardService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const stats = asyncHandler(async (req, res) => {
  const result = await dashboardService.getDashboardStats(req.user);
  res.status(200).json(result);
});

export const railwayDashboardStats = asyncHandler(async (req, res) => {
  const result = await dashboardService.getRailwayDashboardStats(req.user);
  res.status(200).json(result);
});
