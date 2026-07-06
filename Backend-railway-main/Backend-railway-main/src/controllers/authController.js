import { authService } from '../services/authService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const sendOtp = asyncHandler(async (req, res) => {
  const result = await authService.sendOtp(req.body.phone);
  res.status(200).json(result);
});

export const verifyOtp = asyncHandler(async (req, res) => {
  const result = await authService.verifyOtp(req.body.phone, req.body.otp);
  res.status(200).json(result);
});

export const sendEmailOtp = asyncHandler(async (req, res) => {
  const result = await authService.sendEmailOtp(req.body.email);
  res.status(200).json(result);
});

export const verifyEmailOtp = asyncHandler(async (req, res) => {
  const result = await authService.verifyEmailOtp(req.body.email, req.body.otp);
  res.status(200).json(result);
});

export const login = asyncHandler(async (req, res) => {
  const result = await authService.login(req.body.email, req.body.password);
  res.status(200).json(result);
});

export const loginWithMobile = asyncHandler(async (req, res) => {
  const result = await authService.loginWithMobile(req.body.mobile, req.body.password);
  res.status(200).json(result);
});

export const sendForgotPasswordOtp = asyncHandler(async (req, res) => {
  const result = await authService.sendForgotPasswordOtp(req.body.mobile);
  res.status(200).json(result);
});

export const verifyForgotPasswordOtp = asyncHandler(async (req, res) => {
  const result = await authService.verifyForgotPasswordOtp(req.body.mobile, req.body.otp);
  res.status(200).json(result);
});

export const resetPassword = asyncHandler(async (req, res) => {
  const result = await authService.resetPassword(req.body.newPassword, req.body.resetToken);
  res.status(200).json(result);
});

export const sendForgotPasswordEmailOtp = asyncHandler(async (req, res) => {
  const result = await authService.sendForgotPasswordEmailOtp(req.body.email);
  res.status(200).json(result);
});

export const verifyForgotPasswordEmailOtp = asyncHandler(async (req, res) => {
  const result = await authService.verifyForgotPasswordEmailOtp(req.body.email, req.body.otp);
  res.status(200).json(result);
});

export const changePassword = asyncHandler(async (req, res) => {
  const result = await authService.changePassword(req.user.uid, req.body.currentPassword, req.body.newPassword, req.user);
  res.status(200).json(result);
});

export default { sendOtp, verifyOtp, sendEmailOtp, verifyEmailOtp, login, loginWithMobile, sendForgotPasswordOtp, verifyForgotPasswordOtp, resetPassword, sendForgotPasswordEmailOtp, verifyForgotPasswordEmailOtp, changePassword };
