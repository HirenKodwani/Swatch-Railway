import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { notificationService } from './notificationService.js';
import { paginate } from '../utils/paginate.js';

const INSPECTION_TYPES = ['daily', 'surprise', 'ad_hoc', 'complaint_based', 'monthly_review', 'routine', 'random', 'emergency'];
const RATING_MAP = { excellent: 5, good: 4, average: 3, poor: 2, dirty: 1 };

class InspectionService {
  async createInspection(userData, body) {
    const { stationId, platformId, areaId, inspectionType, scheduledDate, inspectorId, remarks } = body;
    if (!stationId || !inspectionType) throw new ValidationError('stationId and inspectionType are required');
    if (!INSPECTION_TYPES.includes(inspectionType)) throw new ValidationError(`inspectionType must be one of: ${INSPECTION_TYPES.join(', ')}`);

    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');

    const ref = db.collection('inspections').doc();
    const data = {
      uid: ref.id, stationId, stationName: stationDoc.data().stationName || '',
      platformId: platformId || null, areaId: areaId || null,
      inspectionType, scheduledDate: scheduledDate || new Date().toISOString().split('T')[0],
      inspectorId: inspectorId || userData.uid,
      inspectorName: userData.fullName || userData.name || '',
      status: 'SCHEDULED',
      ratings: {}, overallScore: null, remarks: remarks || '',
      photos: [], evidence: [],
      auditLog: [{ action: 'CREATED', by: userData.uid, at: new Date().toISOString() }],
      createdBy: userData.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Inspection created', uid: ref.id, inspection: data };
  }

  async getInspections(query = {}) {
    const { stationId, inspectionType, status, inspectorId, limit = 50, cursor } = query;
    let firestoreQuery = db.collection('inspections');
    if (stationId) firestoreQuery = firestoreQuery.where('stationId', '==', stationId);
    if (inspectionType) firestoreQuery = firestoreQuery.where('inspectionType', '==', inspectionType);
    if (status) firestoreQuery = firestoreQuery.where('status', '==', status);
    if (inspectorId) firestoreQuery = firestoreQuery.where('inspectorId', '==', inspectorId);
    const result = await paginate(firestoreQuery, { limit, cursor, orderBy: 'createdAt', orderDir: 'desc' });
    return { count: result.items.length, inspections: result.items, pagination: result.pagination };
  }

  async getInspectionById(uid) {
    const doc = await db.collection('inspections').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Inspection not found');
    return { id: doc.id, ...doc.data() };
  }

  async updateInspection(uid, body) {
    const ref = db.collection('inspections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Inspection not found');
    const updates = {};
    const allowed = ['scheduledDate', 'inspectorId', 'inspectorName', 'remarks', 'status'];
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }
    updates.updatedAt = new Date().toISOString();
    await ref.update(updates);
    return { message: 'Inspection updated', uid };
  }

  async deleteInspection(uid) {
    const ref = db.collection('inspections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Inspection not found');
    await ref.update({ status: 'CANCELLED', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Inspection cancelled' };
  }

  async startInspection(uid, userData) {
    const ref = db.collection('inspections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Inspection not found');
    await ref.update({ status: 'IN_PROGRESS', startedAt: new Date().toISOString(), startedBy: userData.uid, updatedAt: new Date().toISOString() });
    return { message: 'Inspection started', uid };
  }

  async submitRatings(uid, userData, body) {
    const ref = db.collection('inspections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Inspection not found');

    const { ratings, photos, remarks } = body;
    if (!ratings || typeof ratings !== 'object') throw new ValidationError('ratings object is required');

    const scores = {};
    let total = 0, count = 0;
    for (const [key, val] of Object.entries(ratings)) {
      const numeric = RATING_MAP[val.toLowerCase()];
      if (numeric !== undefined) {
        scores[key] = { label: val.toLowerCase(), score: numeric };
        total += numeric;
        count++;
      } else if (typeof val === 'number' && val >= 1 && val <= 5) {
        scores[key] = { label: ['dirty', 'poor', 'average', 'good', 'excellent'][val - 1], score: val };
        total += val;
        count++;
      }
    }

    const overallScore = count > 0 ? Math.round((total / count) * 20) : 0;
    const grade = overallScore >= 80 ? 'Excellent' : overallScore >= 60 ? 'Good' : overallScore >= 40 ? 'Average' : overallScore >= 20 ? 'Poor' : 'Dirty';

    const updates = {
      ratings: scores, overallScore, grade,
      photos: photos || [], remarks: remarks || '',
      status: 'COMPLETED', completedAt: new Date().toISOString(),
      completedBy: userData.uid, updatedAt: new Date().toISOString()
    };
    await ref.update(updates);

    await db.collection('inspection_scores').add({
      inspectionId: uid, stationId: doc.data().stationId,
      overallScore, grade, scoredAt: new Date().toISOString()
    });

    return { message: 'Ratings submitted', uid, overallScore, grade, ratings: scores };
  }

  async approveInspection(uid, userData, body) {
    const ref = db.collection('inspections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Inspection not found');
    await ref.update({
      status: 'APPROVED', approvedBy: userData.uid,
      approvedAt: new Date().toISOString(), approvalRemarks: body.remarks || '',
      updatedAt: new Date().toISOString()
    });
    return { message: 'Inspection approved', uid };
  }

  async rejectInspection(uid, userData, body) {
    const ref = db.collection('inspections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Inspection not found');
    if (!body.reason) throw new ValidationError('Rejection reason is required');
    await ref.update({
      status: 'REJECTED', rejectedBy: userData.uid,
      rejectedAt: new Date().toISOString(), rejectionReason: body.reason,
      updatedAt: new Date().toISOString()
    });
    return { message: 'Inspection rejected', uid };
  }

  async resubmitInspection(uid, userData, body) {
    const ref = db.collection('inspections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Inspection not found');
    await ref.update({
      status: 'RESUBMITTED', resubmittedBy: userData.uid,
      resubmittedAt: new Date().toISOString(), resubmissionRemarks: body.remarks || '',
      updatedAt: new Date().toISOString()
    });
    return { message: 'Inspection resubmitted', uid };
  }

  async getScoreSummary(stationId) {
    if (!stationId) throw new ValidationError('stationId is required');
    const snapshot = await db.collection('inspection_scores')
      .where('stationId', '==', stationId)
      .orderBy('scoredAt', 'desc').limit(30).get();

    let total = 0, count = 0, grades = { Excellent: 0, Good: 0, Average: 0, Poor: 0, Dirty: 0 };
    snapshot.forEach(doc => {
      const d = doc.data();
      total += d.overallScore || 0;
      count++;
      if (grades[d.grade] !== undefined) grades[d.grade]++;
    });

    return {
      stationId, averageScore: count > 0 ? Math.round(total / count) : 0,
      totalInspections: count, gradeDistribution: grades,
      recentScores: []
    };
  }

  // ─── Add Deficiency ───────────────────────────────────────────────────────
  async addDeficiency(uid, deficiency, user) {
    const ref = db.collection('inspections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Inspection not found');
    if (!deficiency.area || !deficiency.description) throw new ValidationError('area and description are required for deficiency');

    const defId = `DEF-${Date.now()}`;
    const now = new Date().toISOString();
    const newDeficiency = {
      defId,
      area: deficiency.area,
      description: deficiency.description,
      severity: deficiency.severity || 'medium',
      assignedTo: deficiency.assignedTo || null,
      assignedToName: deficiency.assignedToName || '',
      closureStatus: 'OPEN',
      closureProof: null,
      closedAt: null,
      closedBy: null,
      addedBy: user.uid,
      addedByName: user.fullName || '',
      addedAt: now,
    };

    await ref.update({
      deficiencies: admin.firestore.FieldValue.arrayUnion(newDeficiency),
      updatedAt: now,
    });
    return { message: 'Deficiency added', defId, deficiency: newDeficiency };
  }

  // ─── Close Deficiency ─────────────────────────────────────────────────────
  async closeDeficiency(uid, defId, closureData, user) {
    const ref = db.collection('inspections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Inspection not found');
    const data = doc.data();
    const deficiencies = data.deficiencies || [];
    const idx = deficiencies.findIndex(d => d.defId === defId);
    if (idx === -1) throw new NotFoundError('Deficiency not found');

    deficiencies[idx] = {
      ...deficiencies[idx],
      closureStatus: 'CLOSED',
      closureProof: closureData.closureProof || '',
      closureRemarks: closureData.remarks || '',
      closedAt: new Date().toISOString(),
      closedBy: user.uid,
      closedByName: user.fullName || '',
    };

    const allClosed = deficiencies.every(d => d.closureStatus === 'CLOSED');
    await ref.update({
      deficiencies,
      allDeficienciesClosed: allClosed,
      updatedAt: new Date().toISOString(),
    });
    return { message: 'Deficiency closed', defId, allDeficienciesClosed: allClosed };
  }

  // ─── Railway Verify Deficiency Closure ───────────────────────────────────
  async verifyDeficiencyClosure(uid, defId, user) {
    const ref = db.collection('inspections').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Inspection not found');
    const data = doc.data();
    const deficiencies = data.deficiencies || [];
    const idx = deficiencies.findIndex(d => d.defId === defId);
    if (idx === -1) throw new NotFoundError('Deficiency not found');
    if (deficiencies[idx].closureStatus !== 'CLOSED') throw new ValidationError('Deficiency must be closed first');

    deficiencies[idx] = {
      ...deficiencies[idx],
      closureStatus: 'RAILWAY_VERIFIED',
      railwayVerifiedBy: user.uid,
      railwayVerifiedAt: new Date().toISOString(),
    };
    await ref.update({ deficiencies, updatedAt: new Date().toISOString() });
    return { message: 'Deficiency closure verified by Railway', defId };
  }
}

export const inspectionService = new InspectionService();
