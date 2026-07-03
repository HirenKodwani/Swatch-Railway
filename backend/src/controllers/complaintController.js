import { complaintService } from '../services/complaintService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await complaintService.createComplaint(req.user, req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await complaintService.getComplaints(req.query);
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await complaintService.getComplaintById(req.params.uid);
  res.status(200).json(result);
});

export const assign = asyncHandler(async (req, res) => {
  const result = await complaintService.assignComplaint(req.params.uid, req.user, req.body);
  res.status(200).json(result);
});

export const resolve = asyncHandler(async (req, res) => {
  const result = await complaintService.resolveComplaint(req.params.uid, req.user, req.body);
  res.status(200).json(result);
});

export const close = asyncHandler(async (req, res) => {
  const result = await complaintService.closeComplaint(req.params.uid, req.user);
  res.status(200).json(result);
});

export const reopen = asyncHandler(async (req, res) => {
  const result = await complaintService.reopenComplaint(req.params.uid, req.user, req.body);
  res.status(200).json(result);
});

export const reject = asyncHandler(async (req, res) => {
  const result = await complaintService.rejectComplaint(req.params.uid, req.user, req.body);
  res.status(200).json(result);
});

export const verify = asyncHandler(async (req, res) => {
  const result = await complaintService.verifyComplaint(req.params.uid, req.user);
  res.status(200).json(result);
});

export const remove = asyncHandler(async (req, res) => {
  await complaintService.deleteComplaint(req.params.uid);
  res.status(200).json({ message: 'Complaint closed' });
});

