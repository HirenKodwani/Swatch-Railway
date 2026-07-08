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
  res.status(200).json({ message: 'Manpower approved' });
});

export const saveScoringDraft = asyncHandler(async (req, res) => {
  res.status(200).json({ message: 'Draft saved' });
});

export const submitScoring = asyncHandler(async (req, res) => {
  res.status(200).json({ message: 'Scoring submitted' });
});

export const acceptRating = asyncHandler(async (req, res) => {
  res.status(200).json({ message: 'Rating accepted' });
});

export const resubmit = asyncHandler(async (req, res) => {
  res.status(200).json({ message: 'Form resubmitted' });
});

export const reject = asyncHandler(async (req, res) => {
  res.status(200).json({ message: 'Form rejected' });
});

export const submitted = asyncHandler(async (req, res) => {
  const result = await premisesFormService.getPremisesForms({ user: req.user, query: { ...req.query, type: 'history' } });
  res.status(200).json(result);
});

export const pendingScoring = asyncHandler(async (req, res) => {
  res.status(200).json({ count: 0, forms: [] });
});
