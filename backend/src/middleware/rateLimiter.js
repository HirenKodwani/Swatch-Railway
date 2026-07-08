import config from '../config/index.js';

const requestCounts = new Map();

export function rateLimiter({ windowMs = 15 * 60 * 1000, max = 20, countFailuresOnly = false } = {}) {
  return (req, res, next) => {
    if (config.nodeEnv === 'development' || process.env.NODE_ENV === 'development') {
      return next();
    }

    const key = req.ip || req.connection.remoteAddress || 'unknown';
    const now = Date.now();

    if (!requestCounts.has(key)) {
      requestCounts.set(key, { timestamps: [] });
    }

    const entry = requestCounts.get(key);
    entry.timestamps = entry.timestamps.filter(ts => now - ts < windowMs);

    if (entry.timestamps.length > max) {
      return res.status(429).json({ error: 'Too many requests. Please try again later.' });
    }

    if (countFailuresOnly) {
      const originalJson = res.json.bind(res);
      res.json = function (body) {
        if (res.statusCode >= 400) {
          entry.timestamps.push(now);
          requestCounts.set(key, entry);
        }
        return originalJson(body);
      };
    } else {
      entry.timestamps.push(now);
      requestCounts.set(key, entry);
    }

    next();
  };
}
