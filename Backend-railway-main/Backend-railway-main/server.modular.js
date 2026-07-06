import { db } from './src/database/index.js';
import { validateEnvironment } from './src/config/env.js';
import app from './src/app.js';
import logger from './src/logger/index.js';
import config from './src/config/index.js';

validateEnvironment();

db.initialize();

logger.info('Server', `Environment: ${config.nodeEnv}`);

app.listen(config.port, async () => {
  logger.info('Server', `Modular Swachh Railways server running on http://localhost:${config.port}`);
  
  // Dynamically load cron after db is fully initialized and server is running
  await import('./src/cron.js');
});
