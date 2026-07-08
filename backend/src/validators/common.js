import { ValidationError } from '../errors/index.js';

export function requireFields(body, fields) {
  const missing = fields.filter(f => {
    const value = body[f];
    return value === undefined || value === null || value === '';
  });

  if (missing.length > 0) {
    throw new ValidationError(`Missing required fields: ${missing.join(', ')}`);
  }
}

export function validateEmail(email) {
  if (!email) return;
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!re.test(email)) {
    throw new ValidationError('Invalid email format');
  }
}

export function validatePhone(phone) {
  if (!phone) return;
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.length !== 10 && cleaned.length !== 12) {
    throw new ValidationError('Phone number must be 10 digits');
  }
}

export function validatePagination(query) {
  const limit = Math.min(parseInt(query.limit, 10) || 50, 200);
  const offset = parseInt(query.offset, 10) || 0;
  return { limit, offset };
}

export function validateDateRange(startDate, endDate) {
  if (!startDate || !endDate) return {};
  const start = new Date(startDate);
  const end = new Date(endDate);
  if (isNaN(start.getTime()) || isNaN(end.getTime())) {
    throw new ValidationError('Invalid date format. Use YYYY-MM-DD');
  }
  if (start > end) {
    throw new ValidationError('Start date must be before end date');
  }
  return { start, end: new Date(end.setHours(23, 59, 59, 999)) };
}

export function sanitizeString(str) {
  if (!str) return str;
  return str.trim().toLowerCase();
}
