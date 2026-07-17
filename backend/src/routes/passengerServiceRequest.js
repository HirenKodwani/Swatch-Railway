import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as passengerController from '../controllers/passengerServiceRequestController.js';

const router = express.Router();

// Transmitter device endpoints (no auth, uses API key)
router.post('/api/passenger-service-requests', passengerController.createFromTransmitter);
router.post('/api/passenger-service-requests/:requestId/device-event', passengerController.handleDeviceEvent);

// Worker authenticated endpoints
router.put('/api/passenger-service-requests/:requestId/accept', verifyToken, requirePermission('MANAGE_PASSENGER_REQUESTS'), passengerController.acceptRequest);
router.put('/api/passenger-service-requests/:requestId/reject', verifyToken, requirePermission('MANAGE_PASSENGER_REQUESTS'), passengerController.rejectRequest);
router.get('/api/passenger-service-requests/worker', verifyToken, passengerController.getWorkerRequests);

// Admin/Supervisor endpoints
router.get('/api/passenger-service-requests', verifyToken, requirePermission('VIEW_PASSENGER_REQUESTS'), passengerController.getAllRequests);
router.get('/api/passenger-service-requests/analytics', verifyToken, requirePermission('VIEW_PASSENGER_REQUESTS'), passengerController.getTimingAnalytics);
router.get('/api/passenger-service-requests/:requestId', verifyToken, requirePermission('VIEW_PASSENGER_REQUESTS'), passengerController.getRequestById);

export default router;