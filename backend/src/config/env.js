import dotenv from 'dotenv';
dotenv.config();

import twilio from 'twilio';
import sgMail from '@sendgrid/mail';

export const TWO_FACTOR_API_KEY = process.env.TWOF_API_KEY;

export const accountSid = process.env.TWILIO_ACCOUNT_SID;
export const authToken = process.env.TWILIO_AUTH_TOKEN;
export const twilioClient = accountSid && authToken ? twilio(accountSid, authToken) : null;

if (process.env.SENDGRID_API_KEY) {
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);
}

export function validateEnvironment() {
  const required = {
    'JWT_SECRET': 'JWT secret for authentication',
    'RESEND_API_KEY': 'Email service API key',
    'TWOF_API_KEY': '2Factor.in API key for SMS OTP',
    'AWS_ACCESS_KEY_ID': 'AWS access key for Rekognition',
    'AWS_SECRET_ACCESS_KEY': 'AWS secret key for Rekognition'
  };

  const missing = [];
  const warnings = [];

  for (const [key, description] of Object.entries(required)) {
    if (!process.env[key]) {
      missing.push(`${key} (${description})`);
    }
  }

  if (!process.env.TWILIO_ACCOUNT_SID) {
    warnings.push('TWILIO_ACCOUNT_SID - SMS features will not work');
  }
  if (!process.env.SENDGRID_API_KEY) {
    warnings.push('SENDGRID_API_KEY - Some email features may not work');
  }

  if (missing.length > 0) {
    console.error(' CRITICAL: Missing required environment variables:');
    missing.forEach(item => console.error(`   - ${item}`));
    console.error('\nPlease add these to your .env file and restart the server.');
    process.exit(1);
  }

  if (warnings.length > 0) {
    console.warn(' WARNING: Optional environment variables missing:');
    warnings.forEach(item => console.warn(`   - ${item}`));
  }

  console.log(' Environment validation passed');
}
