import { db } from '../database/index.js';
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

    const snapshot = await firestoreQuery.get();
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
}

export const cleaningFormService = new CleaningFormService();
