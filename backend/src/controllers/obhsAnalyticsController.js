import { obhsAnalyticsService } from '../services/obhsAnalyticsService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const getJanitorPerformance = asyncHandler(async (req, res) => {
  const { division, zone, startDate, endDate } = req.query;
  const result = await obhsAnalyticsService.getJanitorPerformance(division, zone, startDate, endDate);
  res.status(200).json(result);
});

export const getCoachCleanliness = asyncHandler(async (req, res) => {
  const { division, zone, startDate, endDate } = req.query;
  const result = await obhsAnalyticsService.getCoachCleanliness(division, zone, startDate, endDate);
  res.status(200).json(result);
});

export const getAttendanceCompliance = asyncHandler(async (req, res) => {
  const { division, zone, startDate, endDate } = req.query;
  const result = await obhsAnalyticsService.getAttendanceCompliance(division, zone, startDate, endDate);
  res.status(200).json(result);
});

export const getTaskCompletion = asyncHandler(async (req, res) => {
  const { division, zone, startDate, endDate } = req.query;
  const result = await obhsAnalyticsService.getTaskCompletion(division, zone, startDate, endDate);
  res.status(200).json(result);
});

export const getPassengerRatingTrend = asyncHandler(async (req, res) => {
  const { division, zone, startDate, endDate } = req.query;
  const result = await obhsAnalyticsService.getPassengerRatingTrend(division, zone, startDate, endDate);
  res.status(200).json(result);
});

export const getPenaltyRisk = asyncHandler(async (req, res) => {
  const { division, zone, startDate, endDate } = req.query;
  const result = await obhsAnalyticsService.getPenaltyRisk(division, zone, startDate, endDate);
  res.status(200).json(result);
});

export const getComprehensiveReport = asyncHandler(async (req, res) => {
  const { runInstanceId } = req.params;
  const result = await obhsAnalyticsService.getComprehensiveReport(runInstanceId);
  res.status(200).json(result);
});
