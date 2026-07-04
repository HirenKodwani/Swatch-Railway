import { evidenceService } from '../services/evidenceService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const getEvidenceTypes = asyncHandler(async (req, res) => res.json({ success: true, types: await evidenceService.getEvidenceTypes() }));
export const uploadEvidence = asyncHandler(async (req, res) => res.status(201).json(await evidenceService.uploadEvidence(req.file, req.body, req.user)));
export const uploadMultipleEvidence = asyncHandler(async (req, res) => res.status(201).json(await evidenceService.uploadMultipleEvidence(req.files, req.body, req.user)));
export const uploadEvidenceBase64 = asyncHandler(async (req, res) => res.status(201).json(await evidenceService.uploadEvidenceBase64(req.body.image, req.body, req.user)));
export const getEvidenceById = asyncHandler(async (req, res) => { const r = await evidenceService.getEvidenceById(req.params.id); if (!r) return res.status(404).json({ error: 'Not found' }); res.json({ success: true, evidence: r }); });
export const updateEvidence = asyncHandler(async (req, res) => res.json(await evidenceService.updateEvidence(req.params.id, req.body)));
export const deleteEvidence = asyncHandler(async (req, res) => res.json(await evidenceService.deleteEvidence(req.params.id)));
export const searchEvidence = asyncHandler(async (req, res) => res.json({ success: true, ...await evidenceService.searchEvidence(req.query) }));
export const archiveEvidence = asyncHandler(async (req, res) => res.json(await evidenceService.archiveEvidence(req.params.id)));
export const restoreEvidence = asyncHandler(async (req, res) => res.json(await evidenceService.restoreEvidence(req.params.id)));
export const performArchivalCheck = asyncHandler(async (req, res) => res.json(await evidenceService.performArchivalCheck()));
export const verifyFace = asyncHandler(async (req, res) => {
  if (!req.files || req.files.length < 2) return res.status(400).json({ error: 'Two images required' });
  res.json(await evidenceService.verifyFace(req.files[0].buffer, req.files[1].buffer));
});
export const getStorageAnalytics = asyncHandler(async (req, res) => res.json({ success: true, ...await evidenceService.getStorageAnalytics() }));
export const getPerTrainStorage = asyncHandler(async (req, res) => res.json(await evidenceService.getPerTrainStorage()));
export const getPerContractorStorage = asyncHandler(async (req, res) => res.json(await evidenceService.getPerContractorStorage()));
export const getDailyUploadCount = asyncHandler(async (req, res) => res.json(await evidenceService.getDailyUploadCount(parseInt(req.query.days) || 30)));
export const performBackup = asyncHandler(async (req, res) => res.json(await evidenceService.performBackup(req.body.type || 'daily')));
export const getBackupLogs = asyncHandler(async (req, res) => res.json(await evidenceService.getBackupLogs(parseInt(req.query.limit) || 20)));
