import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

const COMPLAINT_CATEGORIES = ['Broken Tap', 'Broken Seat', 'Leakage', 'Light Failure', 'Dustbin Damage', 'Track Issue', 'Floor Damage', 'Window Broken', 'Door Issue', 'Paint Damage', 'Plumbing', 'Electrical', 'Structure Damage', 'Hygiene Issue', 'Other'];
const COMPLAINT_SEVERITIES = ['low', 'medium', 'high', 'critical'];

class ComplaintService {
  async createComplaint(userData, body) {
    const { stationId, category, severity, description } = body;
    if (!stationId || !category || !description) throw new ValidationError('stationId, category, and description are required');
    if (severity && !COMPLAINT_SEVERITIES.includes(severity)) throw new ValidationError(`severity must be one of: ${COMPLAINT_SEVERITIES.join(', ')}`);

    const ref = db.collection('complaints').doc();
    const slaHours = { low: 72, medium: 48, high: 24, critical: 12 };
    const sla = slaHours[severity || 'medium'];
    const targetClosure = new Date(Date.now() + sla * 3600000).toISOString();

    const data = {
      uid: ref.id, stationId, area: body.area || '', category, severity: severity || 'medium',
      description, evidence: body.evidence || '',
      status: 'REPORTED',
      slaDeadline: targetClosure, slaBreached: false, slaNotified: false,
      reportedBy: userData.uid, reportedByName: userData.fullName || '',
      assignedTo: null, assignedAt: null, targetClosureTime: targetClosure,
      actionTaken: null, closureProof: null, closurePhotoUrl: null, resolvedAt: null,
      rejectionReason: null, reopenedCount: 0,
      escalatedTo: null, escalatedAt: null,
      auditLog: [{ action: 'CREATED', by: userData.uid, at: new Date().toISOString() }],
      createdBy: userData.uid, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Complaint created', uid: ref.id, complaint: data };
  }

  async getComplaints(query = {}) {
    const { stationId, status, severity, category, limit = 50, cursor } = query;
    let q = db.collection('complaints');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (status) q = q.where('status', '==', status);
    if (severity) q = q.where('severity', '==', severity);
    if (category) q = q.where('category', '==', category);
    const result = await paginate(q, { limit, cursor, orderBy: 'createdAt', orderDir: 'desc' });
    return { count: result.items.length, complaints: result.items, pagination: result.pagination };
  }

  async getComplaintById(uid) {
    const doc = await db.collection('complaints').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    return { id: doc.id, ...doc.data() };
  }

  async assignComplaint(uid, userData, body) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    if (!['REPORTED', 'REOPENED'].includes(doc.data().status)) throw new ValidationError('Complaint must be REPORTED or REOPENED');
    if (!body.assignedTo) throw new ValidationError('assignedTo is required');
    await ref.update({ status: 'ASSIGNED', assignedTo: body.assignedTo, assignedAt: new Date().toISOString(), targetClosureTime: body.targetClosureTime || null, updatedAt: new Date().toISOString() });
    return { message: 'Complaint assigned', uid };
  }

  async startProgress(uid, userData) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    if (doc.data().status !== 'ASSIGNED') throw new ValidationError('Complaint must be ASSIGNED to start work');
    await ref.update({ status: 'IN_PROGRESS', startedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Work started on complaint', uid };
  }

  async resolveComplaint(uid, userData, body) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    if (!['ASSIGNED', 'IN_PROGRESS'].includes(doc.data().status)) throw new ValidationError('Complaint must be ASSIGNED or IN_PROGRESS');
    if (!body.actionTaken) throw new ValidationError('actionTaken is required');
    await ref.update({ status: 'RESOLVED', actionTaken: body.actionTaken, closureProof: body.closureProof || '', closurePhotoUrl: body.closurePhotoUrl || null, resolvedAt: new Date().toISOString(), resolvedBy: userData.uid, updatedAt: new Date().toISOString() });
    return { message: 'Complaint resolved', uid };
  }

  async verifyComplaint(uid, userData) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    if (doc.data().status !== 'RESOLVED') throw new ValidationError('Complaint must be RESOLVED');
    await ref.update({ status: 'RAILWAY_VERIFIED', verifiedBy: userData.uid, verifiedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Complaint verified', uid };
  }

  async closeComplaint(uid, userData) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    if (doc.data().status !== 'RAILWAY_VERIFIED') throw new ValidationError('Complaint must be RAILWAY_VERIFIED');
    await ref.update({ status: 'CLOSED', closedBy: userData.uid, closedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Complaint closed', uid };
  }

  async reopenComplaint(uid, userData, body) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    if (!['CLOSED', 'RESOLVED'].includes(doc.data().status)) throw new ValidationError('Complaint must be CLOSED or RESOLVED');
    const current = doc.data();
    await ref.update({ status: 'REOPENED', reopenedCount: (current.reopenedCount || 0) + 1, reopenReason: body.reason || '', reopenedBy: userData.uid, reopenedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Complaint reopened', uid };
  }

  async rejectComplaint(uid, userData, body) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    if (doc.data().status !== 'REPORTED') throw new ValidationError('Complaint must be REPORTED');
    if (!body.reason) throw new ValidationError('Rejection reason is required');
    await ref.update({ status: 'REJECTED', rejectionReason: body.reason, rejectedBy: userData.uid, rejectedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Complaint rejected', uid };
  }

  async escalateComplaint(uid, userData, body) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    if (!['ASSIGNED', 'IN_PROGRESS'].includes(doc.data().status)) throw new ValidationError('Only ASSIGNED or IN_PROGRESS complaints can be escalated');
    await ref.update({ status: 'ESCALATED', escalatedTo: body.escalatedTo, escalatedAt: new Date().toISOString(), escalationReason: body.reason || '', updatedAt: new Date().toISOString() });
    return { message: 'Complaint escalated', uid };
  }

  async checkSlaBreaches() {
    const now = new Date().toISOString();
    const snap = await db.collection('complaints').where('status', 'in', ['REPORTED', 'ASSIGNED', 'IN_PROGRESS']).get();
    let breached = 0;
    const batch = db.batch();
    snap.forEach(doc => {
      const d = doc.data();
      if (d.slaDeadline && d.slaDeadline < now && !d.slaBreached) {
        batch.update(doc.ref, { slaBreached: true, slaBreachedAt: now, updatedAt: now });
        breached++;
      }
    });
    if (breached > 0) await batch.commit();
    return { checked: snap.size, breached };
  }

  async deleteComplaint(uid) {
    const ref = db.collection('complaints').doc(uid);
    if (!(await ref.get()).exists) throw new NotFoundError('Complaint not found');
    await ref.update({ status: 'CLOSED', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Complaint closed' };
  }
}

export const complaintService = new ComplaintService();
