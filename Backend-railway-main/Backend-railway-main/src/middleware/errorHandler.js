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

  if (err.code === 'FAILED_PRECONDITION') {
    logger.error('ErrorHandler', 'Firestore index missing', err);
    return res.status(400).json({
      success: false,
      error: 'Database index missing',
      code: 'INDEX_MISSING',
      details: err.message
    });
  }

  if (err.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      error: err.message,
      code: 'VALIDATION_ERROR'
    });
  }

  logger.error('ErrorHandler', 'Unhandled error', err);
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
