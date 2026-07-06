import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as miscController from '../controllers/miscController.js';

const router = express.Router();

router.get('/health', miscController.health);
router.get('/divisions', verifyToken, miscController.getDivisions);
router.get('/zones', verifyToken, miscController.getZones);
router.get('/depots', verifyToken, miscController.getDepots);
router.get('/pincode', verifyToken, miscController.lookupPincode);
router.get('/enums/:enumName', verifyToken, miscController.getEnumValues);

export default router;
