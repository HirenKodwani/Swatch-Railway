import { dailyActivityService } from '../services/dailyActivityService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const createRecord = asyncHandler(async (req, res) => res.status(201).json(await dailyActivityService.createRecord(req.user, req.body)));
export const listActivities = asyncHandler(async (req, res) => res.json(await dailyActivityService.listActivities(req.query)));
export const getById = asyncHandler(async (req, res) => res.json(await dailyActivityService.getById(req.params.uid)));
export const updateStatus = asyncHandler(async (req, res) => res.json(await dailyActivityService.updateStatus(req.params.uid, req.body.status, req.user, req.body)));
export const getMissedActivities = asyncHandler(async (req, res) => res.json(await dailyActivityService.getMissedActivities(req.query.stationId, req.query.date, req.query.shift)));
export const getPendingActivities = asyncHandler(async (req, res) => res.json(await dailyActivityService.getPendingActivities(req.query.stationId, req.query.date, req.query.shift, req.query.workerId)));
export const getShiftSummary = asyncHandler(async (req, res) => res.json(await dailyActivityService.getShiftSummary(req.query.stationId, req.query.date, req.query.shift)));
export const bulkVerify = asyncHandler(async (req, res) => res.json(await dailyActivityService.bulkVerify(req.body.uids, req.body.status, req.user, req.body.remarks)));
export const deleteRecord = asyncHandler(async (req, res) => res.json(await dailyActivityService.deleteRecord(req.params.uid)));
export const autoGenerate = asyncHandler(async (req, res) => res.json(await dailyActivityService.autoGenerateFromSchedule(req.body.stationId, req.body.date, req.body.shift)));
export const startActivity = asyncHandler(async (req, res) => res.json(await dailyActivityService.startActivity(req.params.uid, req.user)));
export const completeActivity = asyncHandler(async (req, res) => res.json(await dailyActivityService.completeActivity(req.params.uid, req.user, req.body)));
export const getWorkerActivities = asyncHandler(async (req, res) => res.json(await dailyActivityService.getWorkerActivities(req.query.stationId, req.query.date, req.query.shift, req.query.workerId)));
