import { runInstanceService } from '../services/runInstanceService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await runInstanceService.createRunInstance(req.user, req.body);
  res.status(201).json(result);
});

export const update = asyncHandler(async (req, res) => {
  const result = await runInstanceService.updateRunInstance(req.user, req.params.runInstanceId, req.body);
  res.status(200).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const { division: queryDivision, status } = req.query;
  const userRole = (req.user?.role || '').toLowerCase();
  const isSuperAdmin = userRole.includes('super admin') || userRole.includes('company master') || userRole.includes('admin');

  // Super admins see ALL instances; regular users are scoped to their division
  const division = isSuperAdmin ? (queryDivision || null) : (queryDivision || req.user?.division);

  if (!division && !isSuperAdmin) {
    return res.status(400).json({ error: 'Division is required' });
  }
  const result = await runInstanceService.getRunInstancesByDivision(division, status, isSuperAdmin);
  res.status(200).json(result);
});

export const getByParentTrain = asyncHandler(async (req, res) => {
  const { parentTrainId } = req.params;
  const { status } = req.query;
  const result = await runInstanceService.getRunInstanceByTrainNo(parentTrainId);
  if (!result) return res.status(200).json({ message: 'No Run Instances found matching the criteria.', count: 0, data: [] });
  res.status(200).send({ message: 'Run Instances fetched successfully', count: 1, data: [result] });
});

export const remove = asyncHandler(async (req, res) => {
  const result = await runInstanceService.deleteRunInstance(req.params.runInstanceId);
  res.status(200).json(result);
});

export const getObhsRun = asyncHandler(async (req, res) => {
  const result = await runInstanceService.getRunInstanceById(req.params.runId);
  res.status(200).json({ success: true, data: result });
});

export const activateJourney = asyncHandler(async (req, res) => {
  const result = await runInstanceService.activateJourney(req.params.runInstanceId, req.body);
  res.status(200).json(result);
});

export const completeJourney = asyncHandler(async (req, res) => {
  const result = await runInstanceService.completeJourney(req.params.runInstanceId, req.body);
  res.status(200).json(result);
});

export const getActiveRunForWorker = asyncHandler(async (req, res) => {
  const result = await runInstanceService.getActiveRunForWorker(req.user.uid, req.query.trainNo);
  if (!result) return res.status(404).json({ error: 'No active run found' });
  res.status(200).json(result);
});
