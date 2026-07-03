import { platformService } from '../services/platformService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await platformService.createPlatform(req.user, req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await platformService.getPlatforms(req.query);
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await platformService.getPlatformById(req.params.uid);
  res.status(200).json(result);
});

export const update = asyncHandler(async (req, res) => {
  const result = await platformService.updatePlatform(req.params.uid, req.body);
  res.status(200).json(result);
});

export const remove = asyncHandler(async (req, res) => {
  await platformService.deletePlatform(req.params.uid);
  res.status(200).json({ message: 'Platform deleted successfully' });
});

export const getByStation = asyncHandler(async (req, res) => {
  const result = await platformService.getPlatformsByStation(req.params.stationId);
  res.status(200).json(result);
});
