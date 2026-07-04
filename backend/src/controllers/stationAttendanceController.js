import { stationAttendanceService } from '../services/stationAttendanceService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const markAttendance = asyncHandler(async (req, res) => res.status(201).json(await stationAttendanceService.markAttendance(req.user, req.body)));
export const markBulkAttendance = asyncHandler(async (req, res) => res.status(201).json(await stationAttendanceService.markBulkAttendance(req.user, req.body)));
export const getShiftAttendance = asyncHandler(async (req, res) => res.json(await stationAttendanceService.getShiftAttendance(req.query.stationId, req.query.date, req.query.shift)));
export const getPlannedVsActual = asyncHandler(async (req, res) => res.json(await stationAttendanceService.getPlannedVsActual(req.query.stationId, req.query.date, req.query.shift)));
export const getMonthlySummary = asyncHandler(async (req, res) => res.json(await stationAttendanceService.getMonthlySummary(req.query.stationId, req.query.month, req.query.year)));
export const flagAbsences = asyncHandler(async (req, res) => res.json(await stationAttendanceService.flagAbsences(req.body.stationId, req.body.date, req.body.shift)));
export const updateAttendance = asyncHandler(async (req, res) => res.json(await stationAttendanceService.updateAttendance(req.params.attendanceId, req.body)));
export const getWorkerHistory = asyncHandler(async (req, res) => res.json(await stationAttendanceService.getWorkerHistory(req.params.workerId, req.query.stationId, req.query.startDate, req.query.endDate)));
export const applyLeave = asyncHandler(async (req, res) => res.status(201).json(await stationAttendanceService.applyLeave(req.user, req.body)));
export const approveLeave = asyncHandler(async (req, res) => res.json(await stationAttendanceService.approveLeave(req.params.uid, req.user, req.body)));
export const listLeaves = asyncHandler(async (req, res) => res.json(await stationAttendanceService.listLeaves(req.query)));
export const calculateOvertime = asyncHandler(async (req, res) => res.json(await stationAttendanceService.calculateOvertime(req.query.stationId, req.query.month, req.query.year)));
export const exportAttendance = asyncHandler(async (req, res) => {
  const result = await stationAttendanceService.exportAttendance(req.query.stationId, req.query.month, req.query.year);
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', `attachment; filename="${result.filename}"`);
  res.send(result.csv);
});
