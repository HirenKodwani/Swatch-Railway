import { evidenceService } from '../services/evidenceService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const getEvidenceTypes = asyncHandler(async (req, res) => {
  const types = await evidenceService.getEvidenceTypes();
  res.json({ success: true, types });
});

export const uploadEvidence = asyncHandler(async (req, res) => {
  const result = await evidenceService.uploadEvidence(req.file, req.body, req.user);
  res.status(201).json(result);
});

export const uploadEvidenceBase64 = asyncHandler(async (req, res) => {
  const { image, ...metadata } = req.body;
  const result = await evidenceService.uploadEvidenceBase64(image, metadata, req.user);
  res.status(201).json(result);
});

export const getEvidenceById = asyncHandler(async (req, res) => {
  const record = await evidenceService.getEvidenceById(req.params.id);
  if (!record) return res.status(404).json({ error: 'Evidence not found' });
  res.json({ success: true, evidence: record });
});

export const updateEvidence = asyncHandler(async (req, res) => {
  const result = await evidenceService.updateEvidence(req.params.id, req.body);
  res.json(result);
});

export const deleteEvidence = asyncHandler(async (req, res) => {
  const result = await evidenceService.deleteEvidence(req.params.id);
  res.json(result);
});

export const searchEvidence = asyncHandler(async (req, res) => {
  const results = await evidenceService.searchEvidence(req.query);
  res.json({ success: true, ...results });
});

export const archiveEvidence = asyncHandler(async (req, res) => {
  const result = await evidenceService.archiveEvidence(req.params.id);
  res.json(result);
});

export const restoreEvidence = asyncHandler(async (req, res) => {
  const result = await evidenceService.restoreEvidence(req.params.id);
  res.json(result);
});

export const getStorageAnalytics = asyncHandler(async (req, res) => {
  const analytics = await evidenceService.getStorageAnalytics();
  res.json({ success: true, ...analytics });
});

export const getPerTrainStorage = asyncHandler(async (req, res) => {
  const result = await evidenceService.getPerTrainStorage();
  res.json(result);
});

export const getPerContractorStorage = asyncHandler(async (req, res) => {
  const result = await evidenceService.getPerContractorStorage();
  res.json(result);
});

export const getDailyUploadCount = asyncHandler(async (req, res) => {
  const days = parseInt(req.query.days) || 30;
  const result = await evidenceService.getDailyUploadCount(days);
  res.json(result);
});

export const performBackup = asyncHandler(async (req, res) => {
  const type = req.body.type || 'daily';
  const result = await evidenceService.performBackup(type);
  res.json(result);
});

export const getBackupLogs = asyncHandler(async (req, res) => {
  const limit = parseInt(req.query.limit) || 20;
  const result = await evidenceService.getBackupLogs(limit);
  res.json(result);
});
