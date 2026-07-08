import { deploymentService } from '../services/deploymentService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await deploymentService.createDeployment(req.user, req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await deploymentService.getDeployments(req.query);
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await deploymentService.getDeploymentById(req.params.uid);
  res.status(200).json(result);
});

export const update = asyncHandler(async (req, res) => {
  const result = await deploymentService.updateDeployment(req.params.uid, req.body);
  res.status(200).json(result);
});

export const remove = asyncHandler(async (req, res) => {
  await deploymentService.deleteDeployment(req.params.uid);
  res.status(200).json({ message: 'Deployment deleted successfully' });
});

export const workerSchedule = asyncHandler(async (req, res) => {
  const result = await deploymentService.getWorkerSchedule(req.params.workerId, req.query.date);
  res.status(200).json(result);
});

export const manpowerVariance = asyncHandler(async (req, res) => {
  const result = await deploymentService.getManpowerVariance(req.query);
  res.status(200).json(result);
});

export const shiftWiseManpower = asyncHandler(async (req, res) => {
  const result = await deploymentService.getShiftWiseManpower(req.query.date, req.query.stationId);
  res.status(200).json(result);
});
