import { db, admin } from '../database/index.js';

export async function generateFormId(formType, division) {
  const div = division ? division.substring(0, 2).toUpperCase() : 'XX';
  let type = 'PC';
  if (formType === 'coach') { type = 'CC'; }
  else if (formType === 'cts') { type = 'CTS'; }
  const now = new Date();
  const day = String(now.getDate()).padStart(2, '0');
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const year = String(now.getFullYear()).substring(2);
  const dateStr = `${day}${month}${year}`;
  const counterId = `${div}-${type}-${dateStr}`;
  const counterRef = db.collection('counters').doc(counterId);
  let sequentialNumber = 1;
  try {
    await db.runTransaction(async (transaction) => {
      const counterDoc = await transaction.get(counterRef);
      if (!counterDoc.exists) { sequentialNumber = 1; transaction.set(counterRef, { count: sequentialNumber }); }
      else { sequentialNumber = counterDoc.data().count + 1; transaction.update(counterRef, { count: sequentialNumber }); }
    });
  } catch (e) { console.error("Transaction failure:", e); throw new Error("Failed to generate form ID sequence."); }
  const sequentialStr = String(sequentialNumber).padStart(2, '0');
  return `${div}-${type}-${dateStr}-${sequentialStr}`;
}

export function convertToDecimalDays(timeStr) {
  if (!timeStr || typeof timeStr !== 'string' || !timeStr.includes(':')) return 0;
  const parts = timeStr.split(':');
  const d = parseFloat(parts[0]) || 0;
  const h = parseFloat(parts[1]) || 0;
  const m = parseFloat(parts[2]) || 0;
  return d + (h / 24) + (m / 1440);
}

export function safeFormat(val) {
  if (!val) return null;
  const formatOptions = {
    hour: 'numeric', minute: 'numeric', hour12: true,
    day: '2-digit', month: '2-digit', year: '2-digit',
    timeZone: 'Asia/Kolkata'
  };
  if (typeof val.toDate === 'function') {
    return val.toDate().toLocaleString('en-IN', formatOptions);
  }
  const dateObj = new Date(val);
  if (!isNaN(dateObj.getTime())) {
    return dateObj.toLocaleString('en-IN', formatOptions);
  }
  return val;
}

export function isACCoach(coachType) {
  if (!coachType) return false;
  const upper = coachType.toUpperCase();
  const prefixes = ['A', 'B', 'H', 'M', 'C', 'E', 'AC', 'A1', 'B1', 'H1', 'M1', 'C1', 'E1',
    '2AC', '3AC', '1AC', '2A', '3A', '1A', 'EA', 'EC', 'AB', 'HA', 'MA'];
  return prefixes.includes(upper) || /^[ABHMC]\d*$/.test(upper);
}

export function isRoleAllowed(role, allowedRoles) {
  return allowedRoles.some(r => role.toLowerCase().includes(r.toLowerCase()));
}
