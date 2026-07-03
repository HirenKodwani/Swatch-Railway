import { premisesFormService } from '../services/premisesFormService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await premisesFormService.submitPremisesForm(req.user, req.body);
  res.status(200).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await premisesFormService.getPremisesForms({ user: req.user, query: req.query });
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await premisesFormService.getPremisesFormById(req.params.formId);
  res.status(200).json(result);
});

export const approveManpower = asyncHandler(async (req, res) => {
  const result = await premisesFormService.approveManpower(req.user, req.params.formId);
  res.status(200).json(result);
});

export const saveScoringDraft = asyncHandler(async (req, res) => {
  const result = await premisesFormService.saveScoringDraft(req.user, req.params.formId, req.body);
  res.status(200).json(result);
});

export const submitScoring = asyncHandler(async (req, res) => {
  const result = await premisesFormService.submitScoring(req.user, req.params.formId, req.body);
  res.status(200).json(result);
});

export const acceptRating = asyncHandler(async (req, res) => {
  const result = await premisesFormService.acceptRating(req.user, req.params.formId);
  res.status(200).json(result);
});

export const resubmit = asyncHandler(async (req, res) => {
  const result = await premisesFormService.resubmit(req.user, req.params.formId, req.body);
  res.status(200).json(result);
});

export const reject = asyncHandler(async (req, res) => {
  const result = await premisesFormService.rejectForm(req.user, req.params.formId, req.body);
  res.status(200).json(result);
});

export const submitted = asyncHandler(async (req, res) => {
  const result = await premisesFormService.getPremisesForms({ user: req.user, query: { ...req.query, type: 'history' } });
  res.status(200).json(result);
});

export const pendingScoring = asyncHandler(async (req, res) => {
  const result = await premisesFormService.getPendingScoring(req.user);
  res.status(200).json(result);
});
