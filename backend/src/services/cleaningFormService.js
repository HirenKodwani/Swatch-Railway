import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';

class CleaningFormService {
  async submitCleaningForm(userData, body) {
    const { formType, division, depot, contractId, contractNumber, cleaningDate, cleaningShift, startTime, endTime, manpowerCount, machineCount, remarks, latitude, longitude, deviceId, gpsAddress, coachDetails, premiseDetails, photos } = body;
    const { uid, fullName, entityId, entityName } = userData;

    if (!formType) throw new ValidationError('formType is required.');

    const ref = db.collection('cleaningForms').doc();
    const formData = {
      uid: ref.id, formId: `CLN-${Date.now()}`, formType, division, depot: depot || '',
      contractId, contractNumber: contractNumber || '', entityId: entityId || '',
      entityName: entityName || '', submittedBy: uid, submittedByName: fullName,
      status: 'draft',
      cleaningDate: cleaningDate || '', cleaningShift: cleaningShift || '',
      startTime: startTime || '', endTime: endTime || '',
      manpowerCount: manpowerCount || 0, machineCount: machineCount || 0,
      remarks: remarks || '', latitude: latitude || 0, longitude: longitude || 0,
      deviceId: deviceId || '', gpsAddress: gpsAddress || '',
      photos: photos || [],
      auditLog: [{
        action: 'CREATED', performedBy: uid, performedByName: fullName,
        timestamp: new Date().toISOString(), details: 'Form created as draft'
      }],
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };

    if (formType === 'coach' && coachDetails) formData.coachDetails = coachDetails;
    if (formType === 'premise' && premiseDetails) formData.premiseDetails = premiseDetails;

    await ref.set(formData);
    return { message: 'Form created', uid: ref.id, formId: formData.formId };
  }

  async getCleaningForms(filters) {
    const { user, query } = filters;
    const { status, formType, contractId: queryContractId, division: queryDivision } = query;
    const { role, division: userDiv, entityId, userType } = user;

    let firestoreQuery = db.collection('cleaningForms').orderBy('createdAt', 'desc');

    if (userType === 'contractor') {
      firestoreQuery = firestoreQuery.where('entityId', '==', entityId);
    } else if ((role || '').toLowerCase().includes('supervisor')) {
      firestoreQuery = firestoreQuery.where('division', '==', userDiv);
    } else if ((role || '').toLowerCase().includes('admin') || (role || '').toLowerCase().includes('master')) {
      if (queryDivision) firestoreQuery = firestoreQuery.where('division', '==', queryDivision);
    }

    if (status) firestoreQuery = firestoreQuery.where('status', '==', status);
    if (formType) firestoreQuery = firestoreQuery.where('formType', '==', formType);
    if (queryContractId) firestoreQuery = firestoreQuery.where('contractId', '==', queryContractId);

    const snapshot = await firestoreQuery.limit(200).get();
    const forms = [];
    snapshot.forEach(doc => forms.push(doc.data()));
    return { count: forms.length, forms };
  }

  async getCleaningFormById(uid) {
    if (!uid) throw new ValidationError("Form ID is required.");
    const doc = await db.collection('cleaningForms').doc(uid).get();
    if (!doc.exists) throw new NotFoundError("Form not found.");
    return doc.data();
  }

  async submitForm(user, uid) {
    if (!uid) throw new ValidationError("Form ID is required.");
    const ref = db.collection('cleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");
    const form = doc.data();
    if (form.status !== 'draft') throw new ValidationError("Only draft forms can be submitted.");
    await ref.update({
      status: 'SUBMITTED',
      updatedAt: new Date().toISOString(),
      auditLog: admin.firestore.FieldValue.arrayUnion({
        action: 'SUBMITTED',
        performedBy: user.uid,
        performedByName: user.fullName,
        timestamp: new Date().toISOString(),
        details: 'Form submitted for review'
      })
    });
    return { message: 'Form submitted successfully' };
  }

  async approveForm(user, uid) {
    if (!uid) throw new ValidationError("Form ID is required.");
    const ref = db.collection('cleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");
    const form = doc.data();
    if (form.status !== 'SUBMITTED') throw new ValidationError("Only submitted forms can be approved.");
    await ref.update({
      status: 'APPROVED',
      approvedBy: user.uid,
      approvedByName: user.fullName,
      approvedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      auditLog: admin.firestore.FieldValue.arrayUnion({
        action: 'APPROVED',
        performedBy: user.uid,
        performedByName: user.fullName,
        timestamp: new Date().toISOString(),
        details: `Form approved by ${user.fullName}. Scoring section opened.`
      })
    });
    return { message: 'Form approved successfully. Scoring section is now open.' };
  }

  async rejectForm(user, uid, body) {
    if (!uid) throw new ValidationError("Form ID is required.");
    const reason = body?.reason || 'No reason provided';
    const ref = db.collection('cleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");
    const form = doc.data();
    if (form.status !== 'SUBMITTED') throw new ValidationError("Only submitted forms can be rejected.");
    await ref.update({
      status: 'REJECTED',
      rejectedBy: user.uid,
      rejectedByName: user.fullName,
      rejectedAt: new Date().toISOString(),
      rejectionReason: reason,
      updatedAt: new Date().toISOString(),
      auditLog: admin.firestore.FieldValue.arrayUnion({
        action: 'REJECTED',
        performedBy: user.uid,
        performedByName: user.fullName,
        timestamp: new Date().toISOString(),
        details: `Form rejected by ${user.fullName}. Reason: ${reason}`
      })
    });
    return { message: 'Form rejected successfully' };
  }

  async scoreForm(user, uid, body) {
    if (!uid) throw new ValidationError("Form ID is required.");
    const { scoringData, totalScore, maxTotalScore, remarks, grade } = body;
    const ref = db.collection('cleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");
    const form = doc.data();
    if (form.status !== 'APPROVED') throw new ValidationError("Scoring is only allowed for approved forms.");
    const calculatedGrade = grade || (totalScore >= 90 ? 'A' : totalScore >= 80 ? 'B' : totalScore >= 70 ? 'C' : totalScore >= 60 ? 'D' : 'F');
    await ref.update({
      status: 'SCORED',
      score: totalScore,
      grade: calculatedGrade,
      scoringData: scoringData || { criteria: [], totalScore, maxTotalScore, remarks, grade: calculatedGrade },
      scoredBy: user.uid,
      scoredByName: user.fullName,
      scoringAt: new Date().toISOString(),
      remarks: remarks || form.remarks,
      updatedAt: new Date().toISOString(),
      auditLog: admin.firestore.FieldValue.arrayUnion({
        action: 'SCORED',
        performedBy: user.uid,
        performedByName: user.fullName,
        timestamp: new Date().toISOString(),
        details: `Score submitted: ${totalScore}/${maxTotalScore} (Grade: ${calculatedGrade})`
      })
    });
    return { message: 'Score submitted successfully', grade: calculatedGrade };
  }

  async acknowledgeForm(user, uid) {
    if (!uid) throw new ValidationError("Form ID is required.");
    const ref = db.collection('cleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");
    const form = doc.data();
    if (form.status !== 'SCORED') throw new ValidationError("Only scored forms can be acknowledged.");
    await ref.update({
      status: 'ACKNOWLEDGED',
      updatedAt: new Date().toISOString(),
      auditLog: admin.firestore.FieldValue.arrayUnion({
        action: 'ACKNOWLEDGED',
        performedBy: user.uid,
        performedByName: user.fullName,
        timestamp: new Date().toISOString(),
        details: `Contractor acknowledged score: ${form.score}`
      })
    });
    return { message: 'Score acknowledged successfully' };
  }

  async autoApproveForm(uid) {
    if (!uid) throw new ValidationError("Form ID is required.");
    const ref = db.collection('cleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");
    const form = doc.data();
    if (form.status !== 'SCORED') throw new ValidationError("Only scored forms can be auto-approved.");
    const scoringAt = new Date(form.scoringAt);
    const now = new Date();
    const diffMs = now - scoringAt;
    if (diffMs < 30 * 60 * 1000) {
      throw new ValidationError(`Auto-approval requires 30 minutes after scoring. ${Math.ceil((30 * 60 * 1000 - diffMs) / 60000)} minutes remaining.`);
    }
    await ref.update({
      status: 'AUTO-APPROVED',
      autoApprovedAt: now.toISOString(),
      updatedAt: now.toISOString(),
      auditLog: admin.firestore.FieldValue.arrayUnion({
        action: 'AUTO_APPROVED',
        performedBy: 'system',
        performedByName: 'System',
        timestamp: now.toISOString(),
        details: 'Auto-approved after 30-minute timeout'
      })
    });
    return { message: 'Form auto-approved successfully' };
  }

  async lockForm(uid) {
    if (!uid) throw new ValidationError("Form ID is required.");
    const ref = db.collection('cleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");
    const form = doc.data();
    if (form.status !== 'ACKNOWLEDGED' && form.status !== 'AUTO-APPROVED' && form.status !== 'SCORED') {
      throw new ValidationError("Form must be acknowledged, auto-approved, or scored before locking.");
    }
    await ref.update({
      status: 'LOCKED',
      lockedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      auditLog: admin.firestore.FieldValue.arrayUnion({
        action: 'LOCKED',
        performedBy: 'system',
        performedByName: 'System',
        timestamp: new Date().toISOString(),
        details: 'Form locked. Ready for billing.'
      })
    });
    return { message: 'Form locked successfully' };
  }
}

export const cleaningFormService = new CleaningFormService();
