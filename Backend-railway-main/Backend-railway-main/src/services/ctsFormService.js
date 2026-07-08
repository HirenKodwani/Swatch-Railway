import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { generateFormId } from '../utils/helpers.js';

class CtsFormService {
  async submitCtsForm(userData, body) {
    const contractorSupervisor = userData;
    const {
      trainId, formDateTime, platform, actArrival, actDeparture,
      workStart, workEnd, allowedWindow, lateYN, coachesInRake, coachesAttended,
      attendanceStaff, garbageDisposed, nominatedLocation, occupiedToilets, notes,
      submittedTo, signature, contractId
    } = body;

    if (!trainId || !contractId || !formDateTime) {
      throw new ValidationError("Missing mandatory fields (Train or Contract).");
    }

    const [contractDoc, trainDoc, userDoc] = await Promise.all([
      db.collection('contracts').doc(contractId).get(),
      db.collection('trains').doc(trainId).get(),
      submittedTo?.railwayEmployeeId ? db.collection('users').doc(submittedTo.railwayEmployeeId).get() : Promise.resolve(null)
    ]);

    if (!contractDoc.exists) throw new NotFoundError("Contract not found.");
    if (!trainDoc.exists) throw new NotFoundError("Train not found.");

    const contractData = contractDoc.data();
    const trainData = trainDoc.data();
    const railwayEmployeeName = userDoc?.exists ? (userDoc.data().fullName || userDoc.data().name || "Unknown") : "N/A";

    const stationName = contractorSupervisor.division || "Unknown Station";
    const agreementNo = contractData.contractNumber || "N/A";
    const agreementDate = contractData.startDate || "N/A";
    const contractorName = contractData.agencyName || contractData.entityName || "N/A";
    const jobDate = new Date().toISOString().split('T')[0];

    const applicableFor = trainData.TrainApplicableFor || [];
    if (!applicableFor.includes('CTS')) {
      throw new ValidationError("This Train is not applicable for CTS service.");
    }

    const newFormId = await generateFormId('cts', contractorSupervisor.division);

    const ctsFormData = {
      uid: newFormId, formId: newFormId, contractId,
      station: stationName, agreementNo, agreementDate, contractorName, jobDate,
      trainId, trainNumber: trainData.trainNo || "", trainName: trainData.trainName || "",
      formDateTime, actArrival, actDeparture, workStart, workEnd,
      platform: platform || null, allowedWindow: allowedWindow || null,
      lateYN: lateYN || "No", coachesInRake: coachesInRake || 0,
      coachesAttended: coachesAttended || 0, attendanceStaff: attendanceStaff || [],
      garbageDisposed: garbageDisposed || false, nominatedLocation: nominatedLocation || null,
      occupiedToilets: occupiedToilets || 0, notes: notes || "",
      submittedTo: {
        railwayEmployeeId: submittedTo?.railwayEmployeeId || null,
        railwayEmployeeName,
        division: submittedTo?.division || contractorSupervisor.division,
        depot: submittedTo?.depot || contractorSupervisor.depot
      },
      signature: { name: signature?.name || null, date: signature?.date || new Date().toISOString() },
      status: 'SUBMITTED',
      submittedById: contractorSupervisor.uid,
      submittedByName: contractorSupervisor.fullName || contractorSupervisor.name,
      submittedByZone: contractorSupervisor.zone || null,
      submittedByDivision: contractorSupervisor.division || null,
      submittedByDepot: contractorSupervisor.depot || null,
      submittedByEntityId: contractorSupervisor.entityId || null,
      submittedByEntityName: contractorSupervisor.entityName || contractorName,
      createdAt: db.Timestamp()
    };

    await db.collection('ctsForms').doc(newFormId).set(ctsFormData);
    return { message: 'CTS Form submitted successfully.', uid: newFormId, railwayEmployeeName };
  }

  async getCtsForms(filters) {
    const { user, query } = filters;
    const { uid, role, userType, zone, division, entityId } = user;
    const { status, type } = query;

    let firestoreQuery = db.collection('ctsForms');
    const userRole = (role || '').toLowerCase();
    const isMaster = userRole.includes('master') || userRole === 'company master';
    const isAdmin = userRole.includes('admin');

    if (userType === 'railway') {
      if (isMaster) {
        if (zone) firestoreQuery = firestoreQuery.where('submittedByZone', '==', zone);
      } else if (isAdmin) {
        firestoreQuery = firestoreQuery.where('submittedByDivision', '==', division);
      } else {
        firestoreQuery = firestoreQuery.where('submittedTo.railwayEmployeeId', '==', uid);
      }
    } else if (userType === 'contractor') {
      if (!entityId) throw new ValidationError("Company ID missing.");
      firestoreQuery = firestoreQuery.where('submittedByEntityId', '==', entityId);
      if (isMaster) {
      } else if (isAdmin) {
        firestoreQuery = firestoreQuery.where('submittedByDivision', '==', division);
      } else {
        firestoreQuery = firestoreQuery.where('submittedById', '==', uid);
      }
    }

    if (status) {
      firestoreQuery = firestoreQuery.where('status', '==', status);
    } else if (type === 'history') {
      firestoreQuery = firestoreQuery.where('status', 'in', ['SCORED', 'LOCKED', 'AUTO-APPROVED', 'REJECTED_BY_RAILWAY']);
    } else {
      firestoreQuery = firestoreQuery.where('status', 'in', ['SUBMITTED', 'RE-SUBMITTED', 'APPROVED_BY_RAILWAY', 'SCORING_IN_PROGRESS']);
    }

    try {
      const snapshot = await firestoreQuery.get();
      const list = [];
      snapshot.forEach(doc => { list.push({ id: doc.id, ...doc.data() }); });
      list.sort((a, b) => {
        const dateA = a.createdAt ? (a.createdAt.toDate ? a.createdAt.toDate() : new Date(a.createdAt)) : new Date(0);
        const dateB = b.createdAt ? (b.createdAt.toDate ? b.createdAt.toDate() : new Date(b.createdAt)) : new Date(0);
        return dateB - dateA;
      });
      return { count: list.length, forms: list };
    } catch (error) {
      if (error.code === 'FAILED_PRECONDITION') {
        throw new ValidationError('Index Missing. Check Firebase Console.');
      }
      throw error;
    }
  }

  async getCtsFormById(uid) {
    if (!uid) throw new ValidationError("Form ID is required.");
    const doc = await db.collection('ctsForms').doc(uid).get();
    if (!doc.exists) throw new NotFoundError("Form not found.");
    return doc.data();
  }
}

export const ctsFormService = new CtsFormService();
