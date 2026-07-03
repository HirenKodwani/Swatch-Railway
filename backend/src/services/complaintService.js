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
    const data = {
      uid: ref.id, stationId,
      area: body.area || '',
      category, severity: severity || 'medium',
      description,
      evidence: body.evidence || '',
      status: 'REPORTED',
      reportedBy: userData.uid,
      reportedByName: userData.fullName || '',
      assignedTo: null, assignedAt: null, targetClosureTime: null,
      actionTaken: null, closureProof: null, closurePhotoUrl: null, resolvedAt: null,
      rejectionReason: null,
      reopenedCount: 0,
      auditLog: [{ action: 'CREATED', by: userData.uid, at: new Date().toISOString() }],
      createdBy: userData.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
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
    if (!['REPORTED', 'REOPENED'].includes(doc.data().status)) throw new ValidationError('Complaint can only be assigned when status is REPORTED or REOPENED');
    if (!body.assignedTo) throw new ValidationError('assignedTo is required');

    const updates = {
      status: 'ASSIGNED',
      assignedTo: body.assignedTo,
      assignedAt: new Date().toISOString(),
      targetClosureTime: body.targetClosureTime || null,
      updatedAt: new Date().toISOString()
    };
    await ref.update(updates);
    return { message: 'Complaint assigned', uid };
  }

  async resolveComplaint(uid, userData, body) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    if (doc.data().status !== 'ASSIGNED' && doc.data().status !== 'IN_PROGRESS') throw new ValidationError('Complaint must be ASSIGNED or IN_PROGRESS to resolve');
    if (!body.actionTaken) throw new ValidationError('actionTaken is required');

    const updates = {
      status: 'RESOLVED',
      actionTaken: body.actionTaken,
      closureProof: body.closureProof || '',
      closurePhotoUrl: body.closurePhotoUrl || null,
      resolvedAt: new Date().toISOString(),
      resolvedBy: userData.uid,
      updatedAt: new Date().toISOString()
    };
    await ref.update(updates);
    return { message: 'Complaint resolved', uid };
  }

  async verifyComplaint(uid, userData) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    if (doc.data().status !== 'RESOLVED') throw new ValidationError('Complaint must be RESOLVED to verify');
    await ref.update({ status: 'RAILWAY_VERIFIED', verifiedBy: userData.uid, verifiedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Complaint verified', uid };
  }

  async closeComplaint(uid, userData) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    if (doc.data().status !== 'RAILWAY_VERIFIED') throw new ValidationError('Complaint must be RAILWAY_VERIFIED to close');
    await ref.update({ status: 'CLOSED', closedBy: userData.uid, closedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Complaint closed', uid };
  }

  async reopenComplaint(uid, userData, body) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    if (doc.data().status !== 'CLOSED' && doc.data().status !== 'RESOLVED') throw new ValidationError('Complaint must be CLOSED or RESOLVED to reopen');
    const current = doc.data();
    await ref.update({
      status: 'REOPENED',
      reopenedCount: (current.reopenedCount || 0) + 1,
      reopenReason: body.reason || '',
      reopenedBy: userData.uid,
      reopenedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });
    return { message: 'Complaint reopened', uid };
  }

  async rejectComplaint(uid, userData, body) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    if (doc.data().status !== 'REPORTED') throw new ValidationError('Complaint must be REPORTED to reject');
    if (!body.reason) throw new ValidationError('Rejection reason is required');
    await ref.update({ status: 'REJECTED', rejectionReason: body.reason, rejectedBy: userData.uid, rejectedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Complaint rejected', uid };
  }

  async deleteComplaint(uid) {
    const ref = db.collection('complaints').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Complaint not found');
    await ref.update({ status: 'CLOSED', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Complaint closed' };
  }
}

export const complaintService = new ComplaintService();
