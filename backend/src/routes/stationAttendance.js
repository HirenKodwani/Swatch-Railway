import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { stationAttendanceService } from '../services/stationAttendanceService.js';

const router = Router();

// Mark attendance for one worker
router.post('/api/station-attendance/mark', verifyToken, asyncHandler(async (req, res) => {
  const result = await stationAttendanceService.markAttendance(req.user, req.body);
  res.status(201).json(result);
}));

// Bulk mark attendance for shift
router.post('/api/station-attendance/bulk', verifyToken, asyncHandler(async (req, res) => {
  const result = await stationAttendanceService.markBulkAttendance(req.user, req.body);
  res.status(201).json(result);
}));

// Get shift attendance (planned vs actual)
router.get('/api/station-attendance/shift', verifyToken, asyncHandler(async (req, res) => {
  const { stationId, date, shift } = req.query;
  const result = await stationAttendanceService.getShiftAttendance(stationId, date, shift);
  res.status(200).json(result);
}));

// Planned vs actual comparison for a shift
router.get('/api/station-attendance/planned-vs-actual', verifyToken, asyncHandler(async (req, res) => {
  const { stationId, date, shift } = req.query;
  const result = await stationAttendanceService.getPlannedVsActual(stationId, date, shift);
  res.status(200).json(result);
}));

// Monthly summary (for billing)
router.get('/api/station-attendance/monthly-summary', verifyToken, asyncHandler(async (req, res) => {
  const { stationId, month, year } = req.query;
  const result = await stationAttendanceService.getMonthlySummary(stationId, month, year);
  res.status(200).json(result);
}));

// Auto-flag absences at shift end
router.post('/api/station-attendance/flag-absences', verifyToken, asyncHandler(async (req, res) => {
  const { stationId, date, shift } = req.body;
  const result = await stationAttendanceService.flagAbsences(stationId, date, shift);
  res.status(200).json(result);
}));

// Update a single attendance record
router.patch('/api/station-attendance/:attendanceId', verifyToken, asyncHandler(async (req, res) => {
  const result = await stationAttendanceService.updateAttendance(req.params.attendanceId, req.body, req.user);
  res.status(200).json(result);
}));

// Worker attendance history
router.get('/api/station-attendance/worker/:workerId', verifyToken, asyncHandler(async (req, res) => {
  const { stationId, startDate, endDate } = req.query;
  const result = await stationAttendanceService.getWorkerHistory(req.params.workerId, stationId, startDate, endDate);
  res.status(200).json(result);
}));

export default router;
