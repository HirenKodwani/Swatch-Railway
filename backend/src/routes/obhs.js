import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as obhsController from '../controllers/obhsController.js';
import { compareFaces } from '../services/rekognitionService.js';

const router = express.Router();

router.post('/', verifyToken, obhsController.submit);
router.get('/', verifyToken, obhsController.list);
router.get('/counts', verifyToken, obhsController.getStatusCounts);
router.get('/:obhsId', verifyToken, obhsController.getById);
router.put('/:obhsId', verifyToken, obhsController.update);
router.put('/:obhsId/approve', verifyToken, obhsController.approve);

// Attendance endpoints (full paths used by Flutter app)
router.post('/api/obhs/attendance', verifyToken, obhsController.markAttendance);
router.get('/api/obhs/attendance/status', verifyToken, obhsController.getAttendanceStatus);
router.get('/api/obhs/attendance/list', verifyToken, obhsController.listAttendance);
router.post('/api/obhs/attendance/report-issue', verifyToken, obhsController.reportAttendanceIssue);

// Standalone face verification endpoints (used by Flutter WorkerRepository.verifyFace)
router.post('/api/verifyFace', verifyToken, async (req, res) => {
  const { image1Url, image2Url } = req.body;
  if (!image1Url || !image2Url) {
    return res.status(400).send({ success: false, error: 'Both image1Url and image2Url are required.' });
  }
  const result = await compareFaces(image1Url, image2Url);
  if (!result.matched) {
    return res.status(400).send({ success: false, error: 'Identity Verification Failed', details: result.reason });
  }
  res.status(200).send({ success: true, message: 'Face verified successfully', similarity: result.similarity });
});

router.post('/api/compareFace', verifyToken, async (req, res) => {
  const { image1Url, image2Url } = req.body;
  if (!image1Url || !image2Url) {
    return res.status(400).send({ success: false, error: 'Both image1Url and image2Url are required.' });
  }
  const result = await compareFaces(image1Url, image2Url);
  res.status(200).send({ success: result.matched, matched: result.matched, similarity: result.similarity, reason: result.reason });
});

router.post('/api/obhs/attendance/verify-face', verifyToken, async (req, res) => {
  const { image1Url, image2Url } = req.body;
  if (!image1Url || !image2Url) {
    return res.status(400).send({ error: 'Missing parameters', details: 'Both image1Url and image2Url are required.' });
  }
  const result = await compareFaces(image1Url, image2Url);
  if (!result.matched) {
    return res.status(400).send({ success: false, error: 'Identity Verification Failed', details: result.reason });
  }
  res.status(200).send({ success: true, message: 'Face verified successfully', similarity: result.similarity });
});

export default router;
