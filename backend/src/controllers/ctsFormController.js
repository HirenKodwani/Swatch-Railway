import { ctsFormService } from '../services/ctsFormService.js';
import { taskService } from '../services/taskService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await ctsFormService.submitCtsForm(req.user, req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await ctsFormService.getCtsForms({ user: req.user, query: req.query });
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await ctsFormService.getCtsFormById(req.params.formId);
  res.status(200).json(result);
});

export const approveManpower = asyncHandler(async (req, res) => {
  const result = await ctsFormService.approveManpower(req.user, req.params.formId);
  res.status(200).json(result);
});

export const reject = asyncHandler(async (req, res) => {
  const result = await ctsFormService.rejectForm(req.user, req.params.formId, req.body);
  res.status(200).json(result);
});

export const submitScoring = asyncHandler(async (req, res) => {
  const result = await ctsFormService.submitScoring(req.user, req.params.formId, req.body);
  res.status(200).json(result);
});

export const acceptRating = asyncHandler(async (req, res) => {
  const result = await ctsFormService.acceptRating(req.user, req.params.formId);
  res.status(200).json(result);
});

export const resubmit = asyncHandler(async (req, res) => {
  const result = await ctsFormService.resubmit(req.user, req.params.formId, req.body);
  res.status(200).json(result);
});

export const createEmergencyTask = asyncHandler(async (req, res) => {
  const result = await taskService.createEmergencyTask(req.user, req.body);
  res.status(201).json(result);
});
