import { areaService } from '../services/areaService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await areaService.createArea(req.user, req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await areaService.getAreas(req.query);
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await areaService.getAreaById(req.params.uid);
  res.status(200).json(result);
});

export const update = asyncHandler(async (req, res) => {
  const result = await areaService.updateArea(req.params.uid, req.body);
  res.status(200).json(result);
});

export const remove = asyncHandler(async (req, res) => {
  await areaService.deleteArea(req.params.uid);
  res.status(200).json({ message: 'Area deleted successfully' });
});

export const getByStation = asyncHandler(async (req, res) => {
  const result = await areaService.getAreasByStation(req.params.stationId, req.query.section);
  res.status(200).json(result);
});

export const getByPlatform = asyncHandler(async (req, res) => {
  const result = await areaService.getAreasByPlatform(req.params.platformId);
  res.status(200).json(result);
});
