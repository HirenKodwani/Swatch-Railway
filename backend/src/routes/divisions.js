import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import divisionController from '../controllers/divisionController.js';

const router = Router();

router.post('/api/divisions', verifyToken, divisionController.createDivision);
router.get('/api/divisions', verifyToken, divisionController.getDivisions);
router.get('/api/divisions/:id', verifyToken, divisionController.getDivisionById);
router.put('/api/divisions/:id', verifyToken, divisionController.updateDivision);
router.delete('/api/divisions/:id', verifyToken, divisionController.deleteDivision);

export default router;
