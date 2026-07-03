import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import auditController from '../controllers/auditController.js';

const router = Router();

router.get('/api/audit/logs', verifyToken, auditController.getAuditLogs);
router.get('/api/audit/logs/stats', verifyToken, auditController.getAuditStats);
router.get('/api/audit/evidence', verifyToken, auditController.getEvidenceAudit);

export default router;
