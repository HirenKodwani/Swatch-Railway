import { materialService } from '../services/materialService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await materialService.createMaterial(req.user, req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await materialService.getMaterials(req.query);
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await materialService.getMaterialById(req.params.uid);
  res.status(200).json(result);
});

export const update = asyncHandler(async (req, res) => {
  const result = await materialService.updateMaterial(req.params.uid, req.body);
  res.status(200).json(result);
});

export const remove = asyncHandler(async (req, res) => {
  await materialService.deleteMaterial(req.params.uid);
  res.status(200).json({ message: 'Material deleted successfully' });
});

export const issue = asyncHandler(async (req, res) => {
  const result = await materialService.issueMaterial(req.user, { ...req.body, materialId: req.params.uid });
  res.status(201).json(result);
});

export const receive = asyncHandler(async (req, res) => {
  const result = await materialService.receiveMaterial(req.user, { ...req.body, materialId: req.params.uid });
  res.status(201).json(result);
});

export const getStockAlerts = asyncHandler(async (req, res) => {
  const result = await materialService.getStockAlerts(req.query);
  res.status(200).json(result);
});

export const getLogs = asyncHandler(async (req, res) => {
  const result = await materialService.getMaterialLogs(req.query);
  res.status(200).json(result);
});

export const use = asyncHandler(async (req, res) => {
  const result = await materialService.useMaterial(req.user, { ...req.body, materialId: req.params.uid });
  res.status(201).json(result);
});

export const createReorderRequest = asyncHandler(async (req, res) => {
  res.status(201).json(await materialService.createReorderRequest(req.user, req.body));
});

export const approveReorderRequest = asyncHandler(async (req, res) => {
  res.json(await materialService.approveReorderRequest(req.params.uid, req.user, req.body));
});

export const listReorderRequests = asyncHandler(async (req, res) => {
  res.json(await materialService.listReorderRequests(req.query));
});
