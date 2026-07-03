import { coachFormService } from '../services/coachFormService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await coachFormService.submitCoachForm(req.user, req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await coachFormService.getCoachForms({ user: req.user, query: req.query });
  res.status(200).json(result);
});

export const approveManpower = asyncHandler(async (req, res) => {
  const result = await coachFormService.approveFormManpower(req.params.formId, req.user);
  res.status(200).json(result);
});

export const saveScoringDraft = asyncHandler(async (req, res) => {
  const result = await coachFormService.scoreForm(req.params.formId, req.user, { ...req.body, _draft: true });
  res.status(200).json(result);
});

export const submitScoring = asyncHandler(async (req, res) => {
  const result = await coachFormService.scoreForm(req.params.formId, req.user, req.body);
  res.status(200).json(result);
});

export const acceptRating = asyncHandler(async (req, res) => {
  const result = await coachFormService.acceptRating(req.params.formId, req.user);
  res.status(200).json(result);
});

export const resubmit = asyncHandler(async (req, res) => {
  const result = await coachFormService.submitCoachForm(req.user, { ...req.body, formId: req.params.formId });
  res.status(200).json(result);
});

export const reject = asyncHandler(async (req, res) => {
  const result = await coachFormService.rejectForm(req.params.formId, { ...req.user, rejectionComments: req.body.rejectionComments });
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await coachFormService.getCoachFormById(req.params.formId);
  res.status(200).json(result);
});

export const getSubmitted = asyncHandler(async (req, res) => {
  const result = await coachFormService.getCoachForms({ user: req.user, query: { ...req.query, status: 'SUBMITTED' } });
  res.status(200).json(result);
});

export const getPendingScoring = asyncHandler(async (req, res) => {
  const result = await coachFormService.getCoachForms({ user: req.user, query: { ...req.query, status: 'APPROVED' } });
  res.status(200).json(result);
});
