import { executionService } from '../services/executionService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const createPlan = asyncHandler(async (req, res) => res.status(201).json(await executionService.createPlan(req.user, req.body)));
export const listPlans = asyncHandler(async (req, res) => res.json(await executionService.getPlans(req.query)));
export const getPlanById = asyncHandler(async (req, res) => res.json(await executionService.getPlanById(req.params.uid)));
export const updatePlan = asyncHandler(async (req, res) => res.json(await executionService.updatePlan(req.params.uid, req.body)));
export const submitPlan = asyncHandler(async (req, res) => res.json(await executionService.submitPlan(req.params.uid, req.user)));
export const approvePlan = asyncHandler(async (req, res) => res.json(await executionService.approvePlan(req.params.uid, req.user)));
export const rejectPlan = asyncHandler(async (req, res) => res.json(await executionService.rejectPlan(req.params.uid, req.user, req.body)));
export const deletePlan = asyncHandler(async (req, res) => res.json(await executionService.deletePlan(req.params.uid)));
export const createLog = asyncHandler(async (req, res) => res.status(201).json(await executionService.createDailyLog(req.user, req.body)));
export const listLogs = asyncHandler(async (req, res) => res.json(await executionService.getDailyLogs(req.query)));
export const getLogById = asyncHandler(async (req, res) => res.json(await executionService.getDailyLogById(req.params.uid)));
export const updateLog = asyncHandler(async (req, res) => res.json(await executionService.updateDailyLog(req.params.uid, req.body)));
export const deleteLog = asyncHandler(async (req, res) => res.json(await executionService.deleteDailyLog(req.params.uid)));
export const submitLog = asyncHandler(async (req, res) => res.json(await executionService.submitDailyLog(req.params.uid, req.user)));
export const approveLog = asyncHandler(async (req, res) => res.json(await executionService.approveDailyLog(req.params.uid, req.user)));
export const rejectLog = asyncHandler(async (req, res) => res.json(await executionService.rejectDailyLog(req.params.uid, req.user, req.body)));
