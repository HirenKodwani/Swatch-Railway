import logger from '../logger/index.js';

export function requestLogger(req, res, next) {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    const entry = {
      method: req.method, path: req.originalUrl, status: res.statusCode,
      duration: `${duration}ms`, ip: req.ip || req.connection?.remoteAddress,
      userAgent: req.headers['user-agent'] || 'unknown',
      userId: req.user?.uid || 'anonymous'
    };
    if (res.statusCode >= 500) {
      logger.error('HTTP', `${req.method} ${req.originalUrl} ${res.statusCode}`, entry);
    } else if (res.statusCode >= 400) {
      logger.warn('HTTP', `${req.method} ${req.originalUrl} ${res.statusCode}`, entry);
    } else {
      logger.info('HTTP', `${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`, entry);
    }
    if (duration > 2000) {
      logger.warn('SLOW_API', `${req.method} ${req.originalUrl} took ${duration}ms`, entry);
    }
  });
  next();
}
