import { ValidationError } from '../errors/index.js';
import { db } from '../database/index.js';

export async function validateCreateUserInput(body) {
  const { email, password, role, userType, fullName, mobile, zone, division, trainId, trainIds, worker_type, entityId } = body;

  if (!email || !password || !role || !userType) {
    throw new ValidationError("Email, Password, Role, and UserType are required.");
  }

  const normalizedEmail = email.trim().toLowerCase();
  const emailQuery = await db.collection('users').where('email', '==', normalizedEmail).get();
  if (!emailQuery.empty) {
    throw new ValidationError("Email already registered.");
  }

  if (mobile) {
    const mobileQuery = await db.collection('users').where('mobile', '==', mobile).get();
    if (!mobileQuery.empty) {
      throw new ValidationError("Mobile Number already registered.");
    }
  }

  const roleUpper = role.toUpperCase();
  if (roleUpper === 'CTS' || roleUpper === 'CONTRACTOR SUPERVISOR') {
    if (!division || !trainId) {
      throw new ValidationError("Division and Train ID are mandatory for Contractor Supervisor.");
    }
    if (trainIds && trainIds.length > 1) {
      throw new ValidationError("Contractor Supervisor can only be mapped to ONE train.");
    }
  }

  if (roleUpper === 'RAILWAY SUPERVISOR') {
    if (!division || (!trainId && (!trainIds || trainIds.length === 0))) {
      throw new ValidationError("Division and at least one Train ID are mandatory for Railway Supervisor.");
    }
  }

  if (roleUpper.includes('WORKER')) {
    if (!worker_type || !['Janitor', 'Attendant'].includes(worker_type)) {
      throw new ValidationError("worker_type (Janitor or Attendant) is mandatory for workers.");
    }
  }

  if (userType.toLowerCase() === 'contractor') {
    if (!entityId) {
      throw new ValidationError("Contractor users must have an 'entityId' (Company ID).");
    }
    const entityDoc = await db.collection('entities').doc(entityId).get();
    if (!entityDoc.exists) {
      throw new ValidationError("Entity (Company) not found.");
    }
    const userRoleLower = role.toLowerCase();
    if (userRoleLower.includes('admin') || userRoleLower.includes('supervisor')) {
      if (!zone || !division) {
        throw new ValidationError("Zone and Division are mandatory to check Active Contracts.");
      }
    }
  }

  return { valid: true };
}

export async function validateUpdateUserInput(body) {
  const { fullName, designation, mobile, zone, division, depot, role, userType, password, entityId, trainId, trainIds, worker_type } = body;

  const hasUpdates = [fullName, designation, mobile, zone, division, depot, role, userType, password, entityId, trainId, trainIds, worker_type]
    .some(v => v !== undefined);

  if (!hasUpdates) {
    throw new ValidationError("No fields to update provided.");
  }

  return { valid: true };
}

export function validateLoginInput(body) {
  const { email, password } = body;
  if (!email || !password) {
    throw new ValidationError("Email and Password are required.");
  }
  return { valid: true };
}

export function validateOtpInput(body) {
  const { phone, otp, email } = body;
  const hasIdentifier = phone || email;
  if (!hasIdentifier) {
    throw new ValidationError("Phone number or Email is required.");
  }
  return { valid: true };
}

export function validatePasswordInput(body) {
  const { currentPassword, newPassword } = body;
  if (!currentPassword || !newPassword) {
    throw new ValidationError('Current password and new password are required.');
  }
  if (newPassword.length < 6) {
    throw new ValidationError('New password must be at least 6 characters.');
  }
  return { valid: true };
}
