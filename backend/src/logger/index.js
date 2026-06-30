const LOG_LEVELS = { DEBUG: 0, INFO: 1, WARN: 2, ERROR: 3, SECURITY: 4 };

const currentLevel = LOG_LEVELS[process.env.LOG_LEVEL] || LOG_LEVELS.DEBUG;

function formatTimestamp() {
  return new Date().toISOString();
}

function shouldLog(level) {
  return level >= currentLevel;
}

const logger = {
  debug(module, message, data = null) {
    if (!shouldLog(LOG_LEVELS.DEBUG)) return;
    const entry = { timestamp: formatTimestamp(), level: 'DEBUG', module, message, data };
    console.log(JSON.stringify(entry));
  },

  info(module, message, data = null) {
    if (!shouldLog(LOG_LEVELS.INFO)) return;
    const entry = { timestamp: formatTimestamp(), level: 'INFO', module, message, data };
    console.log(JSON.stringify(entry));
  },

  warn(module, message, data = null) {
    if (!shouldLog(LOG_LEVELS.WARN)) return;
    const entry = { timestamp: formatTimestamp(), level: 'WARN', module, message, data };
    console.warn(JSON.stringify(entry));
  },

  error(module, message, error = null) {
    if (!shouldLog(LOG_LEVELS.ERROR)) return;
    const entry = {
      timestamp: formatTimestamp(), level: 'ERROR', module, message,
      error: error ? { message: error.message, stack: error.stack, code: error.code } : null
    };
    console.error(JSON.stringify(entry));
  },

  security(module, action, userId, details = null) {
    if (!shouldLog(LOG_LEVELS.SECURITY)) return;
    const entry = {
      timestamp: formatTimestamp(), level: 'SECURITY', module, action, userId, details
    };
    console.warn(JSON.stringify(entry));
  },

  audit(module, action, actorId, targetId, changes = null) {
    const entry = {
      timestamp: formatTimestamp(), level: 'AUDIT', module, action,
      actorId, targetId, changes
    };
    console.log(JSON.stringify(entry));
  },

  performance(module, operation, durationMs, meta = null) {
    if (!shouldLog(LOG_LEVELS.INFO)) return;
    const entry = {
      timestamp: formatTimestamp(), level: 'PERFORMANCE', module, operation,
      durationMs, meta
    };
    console.log(JSON.stringify(entry));
  }
};

export default logger;
