import { cleaningFormService } from '../services/cleaningFormService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await cleaningFormService.submitCleaningForm(req.user, req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await cleaningFormService.getCleaningForms({ user: req.user, query: req.query });
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await cleaningFormService.getCleaningFormById(req.params.uid);
  res.status(200).json(result);
});

export const saveDraft = asyncHandler(async (req, res) => {
  const result = await cleaningFormService.submitCleaningForm(req.user, { ...req.body, uid: req.params.uid });
  res.status(200).json({ message: 'Draft saved' });
});

export const submit = asyncHandler(async (req, res) => {
  res.status(200).json({ message: 'Form submitted' });
});

export const approve = asyncHandler(async (req, res) => {
  res.status(200).json({ message: 'Form approved' });
});

export const reject = asyncHandler(async (req, res) => {
  res.status(200).json({ message: 'Form rejected' });
});

export const score = asyncHandler(async (req, res) => {
  res.status(200).json({ message: 'Score submitted' });
});

export const acknowledge = asyncHandler(async (req, res) => {
  res.status(200).json({ message: 'Score acknowledged' });
});

export const autoApprove = asyncHandler(async (req, res) => {
  res.status(200).json({ message: 'Form auto-approved' });
});

export const lock = asyncHandler(async (req, res) => {
  res.status(200).json({ message: 'Form locked' });
});

export const dashboard = asyncHandler(async (req, res) => {
  const result = await cleaningFormService.getCleaningForms({ user: req.user, query: req.query });
  res.status(200).json(result);
});

export const report = asyncHandler(async (req, res) => {
  const result = await cleaningFormService.getCleaningFormById(req.params.uid);
  res.status(200).json(result);
});
