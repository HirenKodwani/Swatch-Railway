import { billingService } from '../services/billingService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await billingService.createInvoice(req.user, req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await billingService.getInvoices(req.user, req.query);
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await billingService.getInvoiceById(req.params.invoiceId);
  res.status(200).json(result);
});

export const update = asyncHandler(async (req, res) => {
  const result = await billingService.updateInvoice(req.params.invoiceId, req.user, req.body);
  res.status(200).json(result);
});

export const remove = asyncHandler(async (req, res) => {
  await billingService.deleteInvoice(req.params.invoiceId);
  res.status(200).json({ message: 'Invoice deleted successfully' });
});

export const markPaid = asyncHandler(async (req, res) => {
  const result = await billingService.markInvoicePaid(req.params.invoiceId, req.user);
  res.status(200).json(result);
});

export const getPayments = asyncHandler(async (req, res) => {
  const result = await billingService.getPayments(req.query);
  res.status(200).json(result);
});

export const recordPayment = asyncHandler(async (req, res) => {
  const result = await billingService.recordPayment(req.user, req.body);
  res.status(201).json(result);
});
