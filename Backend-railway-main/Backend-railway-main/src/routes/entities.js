import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import entityController from '../controllers/entityController.js';

const router = Router();

router.post('/api/contractors', verifyToken, entityController.createEntity);
router.put('/api/contractors/:uid', verifyToken, entityController.updateEntity);
router.get('/api/contractors', verifyToken, entityController.getEntities);
router.post('/api/master/approveContractor/:uid', verifyToken, entityController.approveEntity);
router.post('/api/master/rejectContractor/:uid', verifyToken, entityController.rejectEntity);
router.post('/api/admin/suspendContractor/:uid', entityController.suspendEntity);
router.get('/api/contractors/details/:uid', entityController.getEntityDetails);

export default router;
