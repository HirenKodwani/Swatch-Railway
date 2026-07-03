import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { stationBillingService } from '../services/stationBillingService.js';

const router = Router();

// Generate a monthly billing support pack
router.post('/api/station-billing/generate', verifyToken, asyncHandler(async (req, res) => {
  const result = await stationBillingService.generateBillingSupportPack(req.user, req.body);
  res.status(201).json(result);
}));

// List billing packs
router.get('/api/station-billing', verifyToken, asyncHandler(async (req, res) => {
  const result = await stationBillingService.listPacks(req.query);
  res.status(200).json(result);
}));

// Get single billing pack
router.get('/api/station-billing/:uid', verifyToken, asyncHandler(async (req, res) => {
  const result = await stationBillingService.getPackById(req.params.uid);
  res.status(200).json(result);
}));

// Update compliance checklist
router.patch('/api/station-billing/:uid/compliance', verifyToken, asyncHandler(async (req, res) => {
  const result = await stationBillingService.updateCompliance(req.params.uid, req.body.checklist, req.user);
  res.status(200).json(result);
}));

// Submit pack for review
router.post('/api/station-billing/:uid/submit', verifyToken, asyncHandler(async (req, res) => {
  const result = await stationBillingService.submitPack(req.params.uid, req.user);
  res.status(200).json(result);
}));

// Approve pack
router.post('/api/station-billing/:uid/approve', verifyToken, asyncHandler(async (req, res) => {
  const result = await stationBillingService.approvePack(req.params.uid, req.user);
  res.status(200).json(result);
}));

// Reject pack
router.post('/api/station-billing/:uid/reject', verifyToken, asyncHandler(async (req, res) => {
  const result = await stationBillingService.rejectPack(req.params.uid, req.body.reason, req.user);
  res.status(200).json(result);
}));

export default router;
