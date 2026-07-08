import { areaAssignmentService } from '../services/areaAssignmentService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await areaAssignmentService.createAssignment(req.body, req.user);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await areaAssignmentService.listAssignments(req.query, req.user);
  res.status(200).json(result);
});

export const getAreaWorkers = asyncHandler(async (req, res) => {
  const result = await areaAssignmentService.getAreaWorkers(req.params.areaId);
  res.status(200).json(result);
});

export const getWorkerAreas = asyncHandler(async (req, res) => {
  const result = await areaAssignmentService.getWorkerAreas(req.params.workerId);
  res.status(200).json(result);
});

export const update = asyncHandler(async (req, res) => {
  const result = await areaAssignmentService.updateAssignment(req.params.id, req.body, req.user);
  res.status(200).json(result);
});

export const remove = asyncHandler(async (req, res) => {
  const result = await areaAssignmentService.deleteAssignment(req.params.id);
  res.status(200).json(result);
});

export const bulkAssign = asyncHandler(async (req, res) => {
  const result = await areaAssignmentService.bulkAssign(req.body, req.user);
  res.status(201).json(result);
});
