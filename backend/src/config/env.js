import config from './index.js';

export function validateEnvironment() {
  if (!config.jwtSecret) {
    throw new Error('JWT_SECRET environment variable is required');
  }
  if (!config.firebase.serviceAccount) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable is required');
  }
}
