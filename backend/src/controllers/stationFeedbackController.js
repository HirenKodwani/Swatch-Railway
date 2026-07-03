import { stationFeedbackService } from '../services/stationFeedbackService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const sendOtp = asyncHandler(async (req, res) => {
  const result = await stationFeedbackService.sendOtp(req.body);
  res.status(200).json(result);
});

export const verifyOtp = asyncHandler(async (req, res) => {
  const result = await stationFeedbackService.verifyOtp(req.body);
  res.status(200).json(result);
});

export const submit = asyncHandler(async (req, res) => {
  const result = await stationFeedbackService.submitFeedback(req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await stationFeedbackService.listFeedback(req.query);
  res.status(200).json(result);
});

export const summary = asyncHandler(async (req, res) => {
  const result = await stationFeedbackService.getFeedbackSummary(req.params.stationId, req.query);
  res.status(200).json(result);
});

export const qrCode = asyncHandler(async (req, res) => {
  const result = await stationFeedbackService.getStationQr(req.params.stationId);
  res.status(200).json(result);
});
