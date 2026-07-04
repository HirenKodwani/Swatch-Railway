import { dashboardService } from '../services/dashboardService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const stats = asyncHandler(async (req, res) => res.json(await dashboardService.getDashboardStats(req.user)));
export const railwayDashboardStats = asyncHandler(async (req, res) => res.json(await dashboardService.getRailwayDashboardStats(req.user)));
export const stationDashboard = asyncHandler(async (req, res) => res.json(await dashboardService.getStationDashboard(req.params.stationId, req.query)));
export const userStats = asyncHandler(async (req, res) => res.json(await dashboardService.getUserStats()));
export const trainStats = asyncHandler(async (req, res) => res.json(await dashboardService.getTrainStats()));
export const supervisorStats = asyncHandler(async (req, res) => res.json(await dashboardService.getSupervisorStats(req.user)));
export const activeTrains = asyncHandler(async (req, res) => res.json(await dashboardService.getActiveTrains()));
export const activeWorkers = asyncHandler(async (req, res) => res.json(await dashboardService.getActiveWorkers()));
export const allFormsStats = asyncHandler(async (req, res) => res.json(await dashboardService.getAllFormsStats()));
