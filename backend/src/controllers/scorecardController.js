import { scorecardService } from '../services/scorecardService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const createDaily = asyncHandler(async (req, res) => {
  const result = await scorecardService.createDailyScorecard(req.user, req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await scorecardService.getDailyScorecards(req.query);
  res.status(200).json(result);
});

export const monthly = asyncHandler(async (req, res) => {
  const result = await scorecardService.getMonthlyScorecard(req.params.stationId, req.query.month, req.query.year);
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await scorecardService.getScorecardById(req.params.uid);
  res.status(200).json(result);
});

export const update = asyncHandler(async (req, res) => {
  const result = await scorecardService.updateScorecard(req.params.uid, req.body);
  res.status(200).json(result);
});

export const remove = asyncHandler(async (req, res) => {
  await scorecardService.deleteScorecard(req.params.uid);
  res.status(200).json({ message: 'Scorecard deleted' });
});
