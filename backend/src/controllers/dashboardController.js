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

export const userStats = asyncHandler(async (req, res) => {
  const result = await dashboardService.getUserStats(req.user);
  res.status(200).json(result);
});

export const trainStats = asyncHandler(async (req, res) => {
  const result = await dashboardService.getTrainStats(req.user);
  res.status(200).json(result);
});

export const supervisorStats = asyncHandler(async (req, res) => {
  const result = await dashboardService.getSupervisorStats(req.user);
  res.status(200).json(result);
});

export const activeTrains = asyncHandler(async (req, res) => {
  const result = await dashboardService.getActiveTrains(req.user);
  res.status(200).json(result);
});

export const activeWorkers = asyncHandler(async (req, res) => {
  const result = await dashboardService.getActiveWorkers(req.user);
  res.status(200).json(result);
});

export const allFormsStats = asyncHandler(async (req, res) => {
  const result = await dashboardService.getAllFormsStats(req.user);
  res.status(200).json(result);
});
