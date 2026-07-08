import { pestControlService } from '../services/pestControlService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const createChemical = asyncHandler(async (req, res) => {
  res.status(201).json(await pestControlService.createChemical(req.user, req.body));
});
export const listChemicals = asyncHandler(async (req, res) => {
  res.json(await pestControlService.listChemicals());
});
export const stockChemical = asyncHandler(async (req, res) => {
  res.json(await pestControlService.stockChemical(req.params.uid, req.body));
});
export const createPlan = asyncHandler(async (req, res) => {
  res.status(201).json(await pestControlService.createTreatmentPlan(req.user, req.body));
});
export const listPlans = asyncHandler(async (req, res) => {
  res.json(await pestControlService.listTreatmentPlans(req.query));
});
export const getPlanById = asyncHandler(async (req, res) => {
  res.json(await pestControlService.getTreatmentPlanById(req.params.uid));
});
export const updatePlan = asyncHandler(async (req, res) => {
  res.json(await pestControlService.updateTreatmentPlan(req.params.uid, req.body));
});
export const reviewPlan = asyncHandler(async (req, res) => {
  res.json(await pestControlService.reviewTreatmentPlan(req.params.uid, req.user, req.body));
});
export const markTreated = asyncHandler(async (req, res) => {
  res.json(await pestControlService.markTreated(req.params.uid, req.user, req.body));
});
export const deletePlan = asyncHandler(async (req, res) => {
  res.json(await pestControlService.deleteTreatmentPlan(req.params.uid));
});
export const report = asyncHandler(async (req, res) => {
  res.json(await pestControlService.getPestReport(req.query));
});
