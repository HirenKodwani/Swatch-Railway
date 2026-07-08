import { AppError } from '../errors/AppError.js';
import logger from '../logger/index.js';

export function errorHandler(err, req, res, _next) {
  if (err instanceof AppError) {
    logger.error('ErrorHandler', err.message, { code: err.code, statusCode: err.statusCode, details: err.details });
    return res.status(err.statusCode).json({
      success: false,
      error: err.message,
      code: err.code,
      ...(err.details && { details: err.details })
    });
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError' || err.name === 'NotBeforeError') {
    return res.status(401).json({ success: false, error: err.message, code: 'AUTHENTICATION_ERROR' });
  }

  // Firestore FAILED_PRECONDITION errors (missing composite index)
  // SDK returns code as number 9 (gRPC status) or as string 'FAILED_PRECONDITION'/'failed-precondition'
  if (
    err.code === 9 ||
    (typeof err.code === 'string' && ['failed_precondition', 'failed-precondition', 'FAILED_PRECONDITION'].includes(err.code)) ||
    (typeof err.message === 'string' && err.message.includes('FAILED_PRECONDITION') && err.message.includes('index'))
  ) {
    logger.error('ErrorHandler', 'Firestore index missing', err);
    return res.status(400).json({
      success: false,
      error: 'Database index missing. Create the required Firestore composite index.',
      code: 'INDEX_MISSING',
      details: err.message
    });
  }

  if (err.name === 'ValidationError' || err.code === 'VALIDATION_ERROR') {
    return res.status(400).json({
      success: false,
      error: err.message,
      code: 'VALIDATION_ERROR'
    });
  }

  logger.error('ErrorHandler', 'Unhandled error', { message: err.message, code: err.code, type: typeof err.code, stack: err.stack?.split('\n').slice(0, 5).join('\n') });
  return res.status(500).json({
    success: false,
    error: process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message,
    code: 'INTERNAL_ERROR'
  });
}

export function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

export function notFoundHandler(req, res) {
  res.status(404).json({
    success: false,
    error: `Route ${req.method} ${req.originalUrl} not found`,
    code: 'NOT_FOUND'
  });
}
