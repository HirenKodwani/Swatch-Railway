import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import contractController from '../controllers/contractController.js';

const router = Router();

router.post('/api/contracts', verifyToken, contractController.createContract);
router.put('/api/contracts/:uid', verifyToken, contractController.updateContract);
router.get('/api/contracts', verifyToken, contractController.getContracts);
router.get('/api/contracts/:uid', contractController.getContractByUid);
router.get('/api/contracts/number/:contractNumber', contractController.getContractByNumber);
router.get('/api/contracts/by-entity/:entityId', contractController.getContractsByEntity);

export default router;
