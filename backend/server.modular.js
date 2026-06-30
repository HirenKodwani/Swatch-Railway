import { db, admin } from './src/database/index.js';
import { validateEnvironment } from './src/config/env.js';
import app from './src/app.js';
import logger from './src/logger/index.js';
import config from './src/config/index.js';

validateEnvironment();

db.initialize();

logger.info('Server', `Environment: ${config.nodeEnv}`);

async function seedDefaultAdmin() {
  try {
    const adminEmail = 'admin@gmail.com';
    const snapshot = await db.collection('users').where('email', '==', adminEmail).limit(1).get();
    if (snapshot.empty) {
      logger.info('Seed', 'Admin user not found. Creating default admin...');
      await db.collection('users').doc('admin-uid').set({
        uid: 'admin-uid',
        fullName: 'Admin',
        email: adminEmail,
        password: '123456',
        mobile: '9999999990',
        role: 'SUPER_ADMIN',
        userType: 'railway',
        zone: 'NR',
        division: 'DELHI',
        status: 'APPROVED',
        createdAt: new Date().toISOString()
      });
      try {
        await admin.auth().createUser({
          uid: 'admin-uid',
          email: adminEmail,
          password: '123456',
          displayName: 'Admin'
        });
      } catch (authErr) {
        logger.warn('Seed', `Firebase Auth user creation skipped: ${authErr.message}`);
      }
      logger.info('Seed', `Default admin created: ${adminEmail}`);
    } else {
      logger.info('Seed', 'Admin user already exists, skipping seed.');
    }
  } catch (err) {
    logger.error('Seed', `Seed failed: ${err.message}`);
  }
}

import './src/cron.js';
await seedDefaultAdmin();

app.listen(config.port, () => {
  logger.info('Server', `Modular Swachh Railways server running on http://localhost:${config.port}`);
});
