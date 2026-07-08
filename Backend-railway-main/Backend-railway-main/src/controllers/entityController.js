import { entityService } from '../services/entityService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const createEntity = asyncHandler(async (req, res) => {
  const result = await entityService.createEntity(req.user, req.body);
  res.status(201).json(result);
});

export const updateEntity = asyncHandler(async (req, res) => {
  const result = await entityService.updateEntity(req.user, req.params.uid, req.body);
  res.status(200).json(result);
});

export const getEntities = asyncHandler(async (req, res) => {
  const result = await entityService.getEntities(req.user, req.query);
  res.status(200).json(result);
});

export const approveEntity = asyncHandler(async (req, res) => {
  const result = await entityService.approveEntity(req.user, req.params.uid);
  res.status(200).json(result);
});

export const rejectEntity = asyncHandler(async (req, res) => {
  const result = await entityService.rejectEntity(req.user, req.params.uid);
  res.status(200).json(result);
});

export const suspendEntity = asyncHandler(async (req, res) => {
  const result = await entityService.suspendEntity(req.params.uid, req.body.suspensionReason);
  res.status(200).json(result);
});

export const getEntityDetails = asyncHandler(async (req, res) => {
  const result = await entityService.getEntityDetails(req.params.uid);
  res.status(200).json(result);
});

export default { createEntity, updateEntity, getEntities, approveEntity, rejectEntity, suspendEntity, getEntityDetails };
