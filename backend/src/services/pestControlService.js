import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

const VALID_PEST_TYPES = ['rodent', 'cockroach', 'mosquito', 'termite', 'ant', 'bird', 'snake', 'bed_bug', 'fly', 'lizard', 'stray_animal', 'other'];
const VALID_SEVERITIES = ['low', 'medium', 'high', 'critical'];
const VALID_TREATMENT_METHODS = ['spraying', 'baiting', 'fumigation', 'trapping', 'gel_treatment', 'heat_treatment', 'biological', 'physical_removal', 'other'];
const VALID_STATUSES = ['PENDING_REVIEW', 'APPROVED', 'REJECTED', 'FOLLOW_UP', 'RESUBMITTED', 'CLOSED'];

class PestControlService {
  async createChemical(userData, body) {
    const { chemicalName, activeIngredient, manufacturer, dilutionRatio, unit, safetyPrecautions } = body;
    if (!chemicalName) throw new ValidationError('chemicalName is required');
    const ref = db.collection('pest_chemicals').doc();
    const data = {
      uid: ref.id, chemicalName, activeIngredient: activeIngredient || '',
      manufacturer: manufacturer || '', dilutionRatio: dilutionRatio || '',
      unit: unit || 'liter', safetyPrecautions: safetyPrecautions || '',
      currentStock: 0, reorderLevel: 0,
      active: true, createdBy: userData.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Chemical created', uid: ref.id, chemical: data };
  }

  async listChemicals() {
    const snap = await db.collection('pest_chemicals').where('active', '==', true).get();
    const items = [];
    snap.forEach(d => items.push(d.data()));
    return { count: items.length, chemicals: items };
  }

  async stockChemical(uid, body) {
    const ref = db.collection('pest_chemicals').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Chemical not found');
    const qty = parseFloat(body.quantity) || 0;
    await ref.update({
      currentStock: admin.firestore.FieldValue.increment(qty),
      updatedAt: new Date().toISOString()
    });
    return { message: `Added ${qty} to stock` };
  }

  async createTreatmentPlan(userData, body) {
    const { stationId, area, pestType, severity, treatmentMethod, chemicalIds, scheduledDate, frequency, notes } = body;
    if (!stationId || !pestType || !treatmentMethod) throw new ValidationError('stationId, pestType, treatmentMethod are required');

    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');

    const ref = db.collection('pest_treatment_plans').doc();
    const plan = {
      uid: ref.id, stationId, stationName: stationDoc.data().stationName || '',
      area: area || '', pestType, severity: severity || 'medium',
      treatmentMethod, chemicalIds: chemicalIds || [],
      scheduledDate: scheduledDate || '',
      frequency: frequency || 'once', nextDueDate: scheduledDate || '',
      notes: notes || '', status: 'PENDING_REVIEW',
      createdBy: userData.uid, createdByName: userData.fullName || userData.name || '',
      reviewedBy: null, reviewNotes: '', reviewedAt: null,
      treatedAt: null, closedAt: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: new Date().toISOString()
    };
    await ref.set(plan);
    return { message: 'Treatment plan created', uid: ref.id, plan };
  }

  async listTreatmentPlans(query = {}) {
    const { stationId, pestType, status, severity, startDate, endDate, limit = 50, cursor } = query;
    let q = db.collection('pest_treatment_plans');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (pestType) q = q.where('pestType', '==', pestType);
    if (status) q = q.where('status', '==', status);
    if (severity) q = q.where('severity', '==', severity);
    if (startDate) q = q.where('scheduledDate', '>=', startDate);
    if (endDate) q = q.where('scheduledDate', '<=', endDate);
    const result = await paginate(q, { limit, cursor, orderBy: 'scheduledDate', orderDir: 'desc' });
    return { count: result.items.length, plans: result.items, pagination: result.pagination };
  }

  async getTreatmentPlanById(uid) {
    const doc = await db.collection('pest_treatment_plans').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Treatment plan not found');
    return { id: doc.id, ...doc.data() };
  }

  async updateTreatmentPlan(uid, body) {
    const ref = db.collection('pest_treatment_plans').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Treatment plan not found');
    if (!['PENDING_REVIEW', 'REJECTED', 'FOLLOW_UP'].includes(doc.data().status)) throw new ValidationError('Plan cannot be edited in current status');
    const allowed = ['area', 'pestType', 'severity', 'treatmentMethod', 'chemicalIds', 'scheduledDate', 'frequency', 'notes', 'nextDueDate'];
    const updates = { updatedAt: new Date().toISOString() };
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }
    await ref.update(updates);
    return { message: 'Treatment plan updated', uid };
  }

  async reviewTreatmentPlan(uid, userData, body) {
    const ref = db.collection('pest_treatment_plans').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Treatment plan not found');
    const { status, reviewNotes } = body;
    if (!['APPROVED', 'REJECTED', 'FOLLOW_UP'].includes(status)) throw new ValidationError('Status must be APPROVED, REJECTED, or FOLLOW_UP');
    const updates = { status, reviewNotes: reviewNotes || '', reviewedBy: userData.uid, reviewedAt: new Date().toISOString(), updatedAt: new Date().toISOString() };
    await ref.update(updates);
    if (status === 'APPROVED' && doc.data().frequency && doc.data().frequency !== 'once') {
      const nextDate = this.calculateNextDueDate(doc.data().scheduledDate, doc.data().frequency);
      if (nextDate) updates.nextDueDate = nextDate;
    }
    return { message: `Treatment plan ${status.toLowerCase()}`, uid };
  }

  async markTreated(uid, userData, body) {
    const ref = db.collection('pest_treatment_plans').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Treatment plan not found');
    if (doc.data().status !== 'APPROVED') throw new ValidationError('Only approved plans can be marked treated');
    await ref.update({
      status: 'CLOSED', treatedAt: body.treatedAt || new Date().toISOString(),
      treatmentNotes: body.notes || '', treatedBy: userData.uid,
      closedAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    });
    return { message: 'Treatment marked as completed' };
  }

  async deleteTreatmentPlan(uid) {
    const ref = db.collection('pest_treatment_plans').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Treatment plan not found');
    await ref.update({ status: 'inactive', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Treatment plan deactivated' };
  }

  async getPestReport(query = {}) {
    const { stationId, pestType, startDate, endDate } = query;
    let q = db.collection('pest_treatment_plans');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (pestType) q = q.where('pestType', '==', pestType);
    if (startDate) q = q.where('scheduledDate', '>=', startDate);
    if (endDate) q = q.where('scheduledDate', '<=', endDate);
    const snap = await q.get();
    const records = [];
    snap.forEach(d => records.push(d.data()));
    const byPestType = {}; const byStatus = {}; const bySeverity = {};
    records.forEach(r => {
      byPestType[r.pestType] = (byPestType[r.pestType] || 0) + 1;
      byStatus[r.status] = (byStatus[r.status] || 0) + 1;
      bySeverity[r.severity] = (bySeverity[r.severity] || 0) + 1;
    });
    return { totalPlans: records.length, byPestType, byStatus, bySeverity, records };
  }

  calculateNextDueDate(currentDate, frequency) {
    if (!currentDate) return null;
    const d = new Date(currentDate);
    switch (frequency) {
      case 'daily': d.setDate(d.getDate() + 1); break;
      case 'weekly': d.setDate(d.getDate() + 7); break;
      case 'fortnightly': d.setDate(d.getDate() + 14); break;
      case 'monthly': d.setMonth(d.getMonth() + 1); break;
      case 'quarterly': d.setMonth(d.getMonth() + 3); break;
      default: return null;
    }
    return d.toISOString().split('T')[0];
  }
}

export const pestControlService = new PestControlService();
