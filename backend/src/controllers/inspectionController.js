import { inspectionService } from '../services/inspectionService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await inspectionService.createInspection(req.user, req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await inspectionService.getInspections(req.query);
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await inspectionService.getInspectionById(req.params.uid);
  res.status(200).json(result);
});

export const update = asyncHandler(async (req, res) => {
  const result = await inspectionService.updateInspection(req.params.uid, req.body);
  res.status(200).json(result);
});

export const remove = asyncHandler(async (req, res) => {
  await inspectionService.deleteInspection(req.params.uid);
  res.status(200).json({ message: 'Inspection deleted successfully' });
});

export const start = asyncHandler(async (req, res) => {
  const result = await inspectionService.startInspection(req.params.uid, req.user);
  res.status(200).json(result);
});

export const submitRatings = asyncHandler(async (req, res) => {
  const result = await inspectionService.submitRatings(req.params.uid, req.user, req.body);
  res.status(200).json(result);
});

export const approve = asyncHandler(async (req, res) => {
  const result = await inspectionService.approveInspection(req.params.uid, req.user, req.body);
  res.status(200).json(result);
});

export const reject = asyncHandler(async (req, res) => {
  const result = await inspectionService.rejectInspection(req.params.uid, req.user, req.body);
  res.status(200).json(result);
});

export const resubmit = asyncHandler(async (req, res) => {
  const result = await inspectionService.resubmitInspection(req.params.uid, req.user, req.body);
  res.status(200).json(result);
});

export const scoreSummary = asyncHandler(async (req, res) => {
  const result = await inspectionService.getScoreSummary(req.params.stationId);
  res.status(200).json(result);
});

export const addDeficiency = asyncHandler(async (req, res) => {
  const result = await inspectionService.addDeficiency(req.params.uid, req.body, req.user);
  res.status(201).json(result);
});

export const closeDeficiency = asyncHandler(async (req, res) => {
  const result = await inspectionService.closeDeficiency(req.params.uid, req.params.defId, req.body, req.user);
  res.status(200).json(result);
});

export const verifyDeficiency = asyncHandler(async (req, res) => {
  const result = await inspectionService.verifyDeficiencyClosure(req.params.uid, req.params.defId, req.user);
  res.status(200).json(result);
});

