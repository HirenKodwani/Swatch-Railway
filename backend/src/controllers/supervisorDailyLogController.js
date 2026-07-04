import { supervisorDailyLogService } from '../services/supervisorDailyLogService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const createLog = asyncHandler(async (req, res) => {
  const result = await supervisorDailyLogService.createLog(req.user, req.body);
  res.status(201).json(result);
});

export const updateLog = asyncHandler(async (req, res) => {
  const result = await supervisorDailyLogService.updateLog(req.params.uid, req.user, req.body);
  res.status(200).json(result);
});

export const submitLog = asyncHandler(async (req, res) => {
  const result = await supervisorDailyLogService.submitLog(req.params.uid, req.user);
  res.status(200).json(result);
});

export const acknowledgeLog = asyncHandler(async (req, res) => {
  const result = await supervisorDailyLogService.acknowledgeLog(req.params.uid, req.user);
  res.status(200).json(result);
});

export const acceptLog = asyncHandler(async (req, res) => {
  res.json(await supervisorDailyLogService.acceptLog(req.params.uid, req.user));
});

export const rejectLog = asyncHandler(async (req, res) => {
  res.json(await supervisorDailyLogService.rejectLog(req.params.uid, req.user, req.body));
});

export const returnLog = asyncHandler(async (req, res) => {
  res.json(await supervisorDailyLogService.returnLog(req.params.uid, req.user, req.body));
});

export const getLogById = asyncHandler(async (req, res) => {
  const result = await supervisorDailyLogService.getLogById(req.params.uid);
  res.status(200).json(result);
});

export const listLogs = asyncHandler(async (req, res) => {
  const result = await supervisorDailyLogService.listLogs(req.query);
  res.status(200).json(result);
});

export const getShiftHandover = asyncHandler(async (req, res) => {
  const { stationId, date, shift } = req.query;
  const result = await supervisorDailyLogService.getShiftHandover(stationId, date, shift);
  res.status(200).json(result);
});
