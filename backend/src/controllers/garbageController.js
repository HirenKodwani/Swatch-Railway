import { garbageService } from '../services/garbageService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const createWasteType = asyncHandler(async (req, res) => {
  res.status(201).json(await garbageService.createWasteType(req.user, req.body));
});
export const listWasteTypes = asyncHandler(async (req, res) => {
  res.json(await garbageService.listWasteTypes());
});
export const record = asyncHandler(async (req, res) => {
  res.status(201).json(await garbageService.recordCollection(req.user, req.body));
});
export const list = asyncHandler(async (req, res) => {
  res.json(await garbageService.listCollections(req.query));
});
export const getById = asyncHandler(async (req, res) => {
  res.json(await garbageService.getCollectionById(req.params.uid));
});
export const update = asyncHandler(async (req, res) => {
  res.json(await garbageService.updateCollection(req.params.uid, req.body));
});
export const verify = asyncHandler(async (req, res) => {
  res.json(await garbageService.verifyCollection(req.params.uid, req.user));
});
export const approve = asyncHandler(async (req, res) => {
  res.json(await garbageService.approveCollection(req.params.uid, req.user));
});
export const markDisposed = asyncHandler(async (req, res) => {
  res.json(await garbageService.markDisposed(req.params.uid, req.user));
});
export const rejectCollection = asyncHandler(async (req, res) => {
  res.json(await garbageService.rejectCollection(req.params.uid, req.user, req.body));
});
export const report = asyncHandler(async (req, res) => {
  res.json(await garbageService.getGarbageReport(req.query));
});
