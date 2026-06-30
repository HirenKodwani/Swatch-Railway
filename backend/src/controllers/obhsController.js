import { obhsService } from '../services/obhsService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const submit = asyncHandler(async (req, res) => {
  const result = await obhsService.submitOBHS(req.user, req.body);
  res.status(201).json(result);
});

export const update = asyncHandler(async (req, res) => {
  const result = await obhsService.updateOBHS(req.params.obhsId, req.user, req.body);
  res.status(200).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await obhsService.getOBHSList(req.user, req.query);
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await obhsService.getOBHSById(req.params.obhsId);
  res.status(200).json(result);
});

export const approve = asyncHandler(async (req, res) => {
  const result = await obhsService.approveOBHS(req.params.obhsId, req.user, req.body);
  res.status(200).json(result);
});

export const getStatusCounts = asyncHandler(async (req, res) => {
  const result = await obhsService.getOBHSStatusCounts(req.user, req.query);
  res.status(200).json(result);
});

export const markAttendance = asyncHandler(async (req, res) => {
  const result = await obhsService.markAttendance(req.user, req.body);
  res.status(result.isLate ? 200 : 200).json(result);
});

export const getAttendanceStatus = asyncHandler(async (req, res) => {
  const { runInstanceId } = req.query;
  const result = await obhsService.getAttendanceStatus(runInstanceId, req.user.uid);
  res.status(200).json(result);
});

export const listAttendance = asyncHandler(async (req, res) => {
  const filters = { ...req.query, callerId: req.user.uid, role: req.user.role };
  const result = await obhsService.getAttendance(filters);
  res.status(200).json(result);
});

export const reportAttendanceIssue = asyncHandler(async (req, res) => {
  const result = await obhsService.reportAttendanceIssue(req.user, req.body);
  res.status(201).json(result);
});
