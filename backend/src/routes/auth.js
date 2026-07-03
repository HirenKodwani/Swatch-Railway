import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import { rateLimiter } from '../middleware/rateLimiter.js';
import authController from '../controllers/authController.js';

const router = Router();

const authRateLimit = rateLimiter({ windowMs: 15 * 60 * 1000, max: 20 });

router.post('/api/auth/send-otp', authRateLimit, authController.sendOtp);
router.post('/api/auth/verify-otp', authRateLimit, authController.verifyOtp);
router.post('/api/auth/send-email-otp', authRateLimit, authController.sendEmailOtp);
router.post('/api/auth/verify-email-otp', authRateLimit, authController.verifyEmailOtp);
router.post('/api/auth/login', authRateLimit, authController.login);
router.post('/api/auth/loginWithMobile', authRateLimit, authController.loginWithMobile);
router.post('/api/auth/forgot-password/send-otp', authRateLimit, authController.sendForgotPasswordOtp);
router.post('/api/auth/forgot-password/verify-otp', authRateLimit, authController.verifyForgotPasswordOtp);
router.post('/api/auth/forgot-password/reset', authRateLimit, authController.resetPassword);
router.post('/api/auth/forgot-password/email/send-otp', authRateLimit, authController.sendForgotPasswordEmailOtp);
router.post('/api/auth/forgot-password/email/verify-otp', authRateLimit, authController.verifyForgotPasswordEmailOtp);
router.post('/api/auth/change-password', verifyToken, authController.changePassword);
router.post('/api/user/update-profile', verifyToken, authController.updateProfile);

export default router;
