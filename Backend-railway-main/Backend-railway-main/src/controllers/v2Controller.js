import { v2Service } from '../services/v2Service.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const getRunInstance = asyncHandler(async (req, res) => {
  const result = await v2Service.getRunInstanceV2(req.params.runInstanceId);
  res.status(200).json(result);
});

export const listRunInstances = asyncHandler(async (req, res) => {
  const result = await v2Service.listRunInstancesV2(req.user, req.query);
  res.status(200).json(result);
});

export const getCoachForm = asyncHandler(async (req, res) => {
  const result = await v2Service.getCoachFormV2(req.params.formId);
  res.status(200).json(result);
});

export const listCoachForms = asyncHandler(async (req, res) => {
  const result = await v2Service.listCoachFormsV2(req.user, req.query);
  res.status(200).json(result);
});

export const getPremisesForm = asyncHandler(async (req, res) => {
  const result = await v2Service.getPremisesFormV2(req.params.formId);
  res.status(200).json(result);
});

export const listPremisesForms = asyncHandler(async (req, res) => {
  const result = await v2Service.listPremisesFormsV2(req.user, req.query);
  res.status(200).json(result);
});

export const getCtsForm = asyncHandler(async (req, res) => {
  const result = await v2Service.getCtsFormV2(req.params.formId);
  res.status(200).json(result);
});

export const listCtsForms = asyncHandler(async (req, res) => {
  const result = await v2Service.listCtsFormsV2(req.user, req.query);
  res.status(200).json(result);
});

export const getCleaningForm = asyncHandler(async (req, res) => {
  const result = await v2Service.getCleaningFormV2(req.params.uid);
  res.status(200).json(result);
});

export const listCleaningForms = asyncHandler(async (req, res) => {
  const result = await v2Service.listCleaningFormsV2(req.user, req.query);
  res.status(200).json(result);
});

export const getTask = asyncHandler(async (req, res) => {
  const result = await v2Service.getTaskV2(req.params.taskId);
  res.status(200).json(result);
});

export const listTasks = asyncHandler(async (req, res) => {
  const result = await v2Service.listTasksV2(req.user, req.query);
  res.status(200).json(result);
});

export const getOBHS = asyncHandler(async (req, res) => {
  const result = await v2Service.getOBHSV2(req.params.obhsId);
  res.status(200).json(result);
});

export const listOBHS = asyncHandler(async (req, res) => {
  const result = await v2Service.listOBHSV2(req.user, req.query);
  res.status(200).json(result);
});
