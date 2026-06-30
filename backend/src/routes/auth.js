import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import authController from '../controllers/authController.js';

const router = Router();

router.post('/api/auth/send-otp', authController.sendOtp);
router.post('/api/auth/verify-otp', authController.verifyOtp);
router.post('/api/auth/send-email-otp', authController.sendEmailOtp);
router.post('/api/auth/verify-email-otp', authController.verifyEmailOtp);
router.post('/api/auth/login', authController.login);
router.post('/api/auth/loginWithMobile', authController.loginWithMobile);
router.post('/api/auth/forgot-password/send-otp', authController.sendForgotPasswordOtp);
router.post('/api/auth/forgot-password/verify-otp', authController.verifyForgotPasswordOtp);
router.post('/api/auth/forgot-password/reset', authController.resetPassword);
router.post('/api/auth/forgot-password/email/send-otp', authController.sendForgotPasswordEmailOtp);
router.post('/api/auth/forgot-password/email/verify-otp', authController.verifyForgotPasswordEmailOtp);
router.post('/api/auth/change-password', verifyToken, authController.changePassword);

export default router;
