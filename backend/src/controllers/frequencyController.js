import { frequencyService } from '../services/frequencyService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await frequencyService.createFrequency(req.user, req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await frequencyService.getFrequencies(req.query);
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await frequencyService.getFrequencyById(req.params.uid);
  res.status(200).json(result);
});

export const update = asyncHandler(async (req, res) => {
  const result = await frequencyService.updateFrequency(req.params.uid, req.body);
  res.status(200).json(result);
});

export const remove = asyncHandler(async (req, res) => {
  await frequencyService.deleteFrequency(req.params.uid);
  res.status(200).json({ message: 'Frequency deleted successfully' });
});
