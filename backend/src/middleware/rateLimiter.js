const requestCounts = new Map();

export function rateLimiter({ windowMs = 15 * 60 * 1000, max = 20 } = {}) {
  return (req, res, next) => {
    const key = req.ip || req.connection.remoteAddress || 'unknown';
    const now = Date.now();

    if (!requestCounts.has(key)) {
      requestCounts.set(key, []);
    }

    const timestamps = requestCounts.get(key).filter(ts => now - ts < windowMs);
    timestamps.push(now);
    requestCounts.set(key, timestamps);

    if (timestamps.length > max) {
      return res.status(429).json({ error: 'Too many requests. Please try again later.' });
    }

    next();
  };
}
