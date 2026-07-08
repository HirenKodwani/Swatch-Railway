import { divisionService } from '../services/divisionService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const createDivision = asyncHandler(async (req, res) => {
  const result = await divisionService.createDivision(req.body);
  res.status(201).json(result);
});

export const getDivisions = asyncHandler(async (req, res) => {
  const result = await divisionService.getDivisions({ zone: req.query.zone });
  res.status(200).json(result);
});

export const getDivisionById = asyncHandler(async (req, res) => {
  const result = await divisionService.getDivisionById(req.params.id);
  res.status(200).json(result);
});

export const updateDivision = asyncHandler(async (req, res) => {
  const result = await divisionService.updateDivision(req.params.id, req.body);
  res.status(200).json(result);
});

export const deleteDivision = asyncHandler(async (req, res) => {
  const result = await divisionService.deleteDivision(req.params.id);
  res.status(200).json(result);
});

export default { createDivision, getDivisions, getDivisionById, updateDivision, deleteDivision };
