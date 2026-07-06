import { reportService } from '../services/reportService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const generate = asyncHandler(async (req, res) => {
  const result = await reportService.generateReport(req.user, req.body);
  res.status(200).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await reportService.getReports(req.user, req.query);
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await reportService.getReportById(req.params.reportId);
  res.status(200).json(result);
});

export const remove = asyncHandler(async (req, res) => {
  await reportService.deleteReport(req.params.reportId);
  res.status(200).json({ message: 'Report deleted successfully' });
});

export const export_report = asyncHandler(async (req, res) => {
  const result = await reportService.exportReport(req.params.reportId, req.query.format);
  res.redirect(result);
});
