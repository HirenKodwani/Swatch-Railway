import express from 'express';
import multer from 'multer';
import { verifyToken } from '../middleware/auth.js';
import * as mediaController from '../controllers/mediaController.js';

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!'), false);
    }
  }
});

router.post('/upload', verifyToken, upload.fields([{ name: 'file', maxCount: 1 }, { name: 'image', maxCount: 1 }]), mediaController.upload);
router.get('/', verifyToken, mediaController.list);
router.delete('/:fileId', verifyToken, mediaController.delete_file);
router.get('/:fileId/url', verifyToken, mediaController.getPublicUrl);

export default router;
