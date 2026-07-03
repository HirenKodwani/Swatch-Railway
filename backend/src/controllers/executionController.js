import { executionService } from '../services/executionService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const createPlan = asyncHandler(async (req, res) => {
  const result = await executionService.createPlan(req.user, req.body);
  res.status(201).json(result);
});

export const listPlans = asyncHandler(async (req, res) => {
  const result = await executionService.getPlans(req.query);
  res.status(200).json(result);
});

export const getPlanById = asyncHandler(async (req, res) => {
  const result = await executionService.getPlanById(req.params.uid);
  res.status(200).json(result);
});

export const updatePlan = asyncHandler(async (req, res) => {
  const result = await executionService.updatePlan(req.params.uid, req.body);
  res.status(200).json(result);
});

export const submitPlan = asyncHandler(async (req, res) => {
  const result = await executionService.submitPlan(req.params.uid, req.user);
  res.status(200).json(result);
});

export const approvePlan = asyncHandler(async (req, res) => {
  const result = await executionService.approvePlan(req.params.uid, req.user);
  res.status(200).json(result);
});

export const rejectPlan = asyncHandler(async (req, res) => {
  const result = await executionService.rejectPlan(req.params.uid, req.user, req.body);
  res.status(200).json(result);
});

export const deletePlan = asyncHandler(async (req, res) => {
  await executionService.deletePlan(req.params.uid);
  res.status(200).json({ message: 'Execution plan deleted' });
});

export const createLog = asyncHandler(async (req, res) => {
  const result = await executionService.createDailyLog(req.user, req.body);
  res.status(201).json(result);
});

export const listLogs = asyncHandler(async (req, res) => {
  const result = await executionService.getDailyLogs(req.query);
  res.status(200).json(result);
});

export const getLogById = asyncHandler(async (req, res) => {
  const result = await executionService.getDailyLogById(req.params.uid);
  res.status(200).json(result);
});
