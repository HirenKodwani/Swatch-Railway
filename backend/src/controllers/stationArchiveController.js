import { stationArchiveService } from '../services/stationArchiveService.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import logger from '../logger/index.js';

export const triggerArchive = asyncHandler(async (req, res) => {
  const { stationId, archiveType, month, year } = req.body;
  logger.info('triggerArchive', { stationId, archiveType, month, year, userId: req.user?.uid });
  const result = await stationArchiveService.triggerArchive(stationId, archiveType, month, year, req.user);
  res.status(201).json(result);
});

export const listArchives = asyncHandler(async (req, res) => {
  const result = await stationArchiveService.listArchives(req.query);
  res.status(200).json(result);
});

export const getArchiveById = asyncHandler(async (req, res) => {
  const result = await stationArchiveService.getArchiveById(req.params.uid);
  res.status(200).json(result);
});

export const purgeArchives = asyncHandler(async (req, res) => {
  const { stationId, archiveType, olderThanMonths } = req.body;
  const result = await stationArchiveService.purgeArchives(stationId, archiveType, olderThanMonths);
  res.status(200).json(result);
});
