import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { dailyActivityService } from '../services/dailyActivityService.js';

const router = Router();

// Create a new activity record
router.post('/api/station-activities', verifyToken, asyncHandler(async (req, res) => {
  const result = await dailyActivityService.createRecord(req.user, req.body);
  res.status(201).json(result);
}));

// List activities (filter by stationId, date, shift, areaId, status)
router.get('/api/station-activities', verifyToken, asyncHandler(async (req, res) => {
  const result = await dailyActivityService.listActivities(req.query);
  res.status(200).json(result);
}));

// Get single activity record
router.get('/api/station-activities/:uid', verifyToken, asyncHandler(async (req, res) => {
  const result = await dailyActivityService.getById(req.params.uid);
  res.status(200).json(result);
}));

// Update status of a single activity
router.patch('/api/station-activities/:uid/status', verifyToken, asyncHandler(async (req, res) => {
  const { status, ...extra } = req.body;
  const result = await dailyActivityService.updateStatus(req.params.uid, status, req.user, extra);
  res.status(200).json(result);
}));

// Get missed activities for a date/station/shift
router.get('/api/station-activities/missed', verifyToken, asyncHandler(async (req, res) => {
  const { stationId, date, shift } = req.query;
  const result = await dailyActivityService.getMissedActivities(stationId, date, shift);
  res.status(200).json(result);
}));

// Get pending activities (worker view)
router.get('/api/station-activities/pending', verifyToken, asyncHandler(async (req, res) => {
  const { stationId, date, shift, workerId } = req.query;
  const result = await dailyActivityService.getPendingActivities(stationId, date, shift, workerId);
  res.status(200).json(result);
}));

// Shift summary (completed/pending/total counts)
router.get('/api/station-activities/shift-summary', verifyToken, asyncHandler(async (req, res) => {
  const { stationId, date, shift } = req.query;
  const result = await dailyActivityService.getShiftSummary(stationId, date, shift);
  res.status(200).json(result);
}));

// Bulk verify (approve or reject multiple activities)
router.post('/api/station-activities/bulk-verify', verifyToken, asyncHandler(async (req, res) => {
  const { uids, status, remarks } = req.body;
  const result = await dailyActivityService.bulkVerify(uids, status, req.user, remarks);
  res.status(200).json(result);
}));

export default router;
