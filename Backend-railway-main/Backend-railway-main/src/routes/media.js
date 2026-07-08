import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as mediaController from '../controllers/mediaController.js';

const router = express.Router();

router.post('/upload', verifyToken, mediaController.upload);
router.get('/', verifyToken, mediaController.list);
router.delete('/:fileId', verifyToken, mediaController.delete_file);
router.get('/:fileId/url', verifyToken, mediaController.getPublicUrl);

export default router;
