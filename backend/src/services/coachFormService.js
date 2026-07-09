import { db } from '../database/index.js';
import { NotFoundError, ValidationError, ForbiddenError } from '../errors/index.js';
import { PENALTY_MAP } from '../config/constants.js';
import { generateFormId } from '../utils/helpers.js';

class CoachFormService {
  async submitCoachForm(userData, body) {
    const contractorSupervisor = userData;
    const { trainId, formDateTime, coachCount, machinesUsed, chemicals, manpower, submittedTo, signature, contractId } = body;

    if (!trainId || !formDateTime || !chemicals || !manpower || !submittedTo || !signature || !contractId) {
      throw new ValidationError("Please fill all mandatory fields (including Contract).");
    }

    const contractDoc = await db.collection('contracts').doc(contractId).get();
    if (!contractDoc.exists) throw new NotFoundError("Selected Contract not found.");

    const contractData = contractDoc.data();
    const status = (contractData.status || "").toLowerCase();
    if (status !== 'active') {
      throw new ValidationError(`Selected Contract is ${contractData.status} (Not Active).`);
    }
    if (contractData.endDate) {
      const today = new Date();
      const endDate = new Date(contractData.endDate);
      endDate.setHours(23, 59, 59, 999);
      if (today > endDate) {
        throw new ValidationError("Selected Contract has Expired.");
      }
    }

    const categories = contractData.workCategories || [];
    let hasCoachAccess = false;
    if (Array.isArray(categories)) {
      hasCoachAccess = categories.some(cat => cat.toLowerCase().includes('coach'));
    } else if (typeof categories === 'string') {
      hasCoachAccess = categories.toLowerCase().includes('coach');
    }
    if (!hasCoachAccess) {
      throw new ForbiddenError("This Contract does not allow Coach Cleaning work.");
    }

    let trainName = null;
    let fetchedTrainNo = "";
    if (trainId) {
      const trainDoc = await db.collection('trains').doc(trainId).get();
      if (trainDoc.exists) {
        const tData = trainDoc.data();
        trainName = tData.trainName || null;
        fetchedTrainNo = tData.trainNo || tData.trainNumber || "";
      }
    }

    let supervisorName = null;
    if (submittedTo && submittedTo.railwayEmployeeId) {
      const userDoc = await db.collection('users').doc(submittedTo.railwayEmployeeId).get();
      if (userDoc.exists) {
        supervisorName = userDoc.data().fullName || null;
      }
    }

    const newFormId = await generateFormId('coach', contractorSupervisor.division);
    const entityName = userData.entityName || contractData.entityName || contractData.agencyName || "Unknown Agency";

    const docRef = db.collection('coachForms').doc(newFormId);
    await docRef.set({
      uid: newFormId,
      formId: newFormId,
      trainId,
      trainName,
      trainNumber: fetchedTrainNo,
      formDateTime,
      coachCount: coachCount || null,
      machinesUsed: machinesUsed || [],
      chemicals,
      manpower: manpower || [],
      submittedTo: {
        railwayEmployeeId: submittedTo.railwayEmployeeId || null,
        railwayEmployeeName: supervisorName,
        division: submittedTo.division || null,
        depot: submittedTo.depot || null
      },
      signature: {
        name: signature.name || null,
        date: signature.date || null
      },
      contractId,
      status: 'SUBMITTED',
      submittedById: contractorSupervisor.uid,
      submittedByName: contractorSupervisor.fullName,
      submittedByZone: contractorSupervisor.zone || null,
      submittedByDivision: contractorSupervisor.division || null,
      submittedByDepot: contractorSupervisor.depot || null,
      submittedByEntityId: contractorSupervisor.entityId || null,
      submittedByEntityName: entityName,
      createdAt: db.Timestamp()
    });

    return { message: 'Coach form submitted successfully.', uid: newFormId };
  }

  async getCoachForms(filters) {
    const { user, query } = filters;
    const { uid, role, userType, zone, division, entityId } = user;
    const { status, type } = query;

    let firestoreQuery = db.collection('coachForms');
    const userRole = (role || "").toLowerCase().replace(/_/g, " ");
    const isMaster = userRole.includes('master') || userRole === 'company master';
    const isAdmin = (!userRole.includes("super admin") && userRole.includes("admin"));

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
      const snapshot = await firestoreQuery.orderBy('createdAt', 'desc').limit(200).get();
      const list = [];
      snapshot.forEach(d => list.push(d.data()));
      return { count: list.length, forms: list };
    } catch (error) {
      if (error.code === 'FAILED_PRECONDITION') {
        throw new ValidationError('Index Missing. Check Firebase Console.');
      }
      throw error;
    }
  }

  async getCoachFormById(uid) {
    if (!uid) throw new ValidationError("Form ID is required.");
    const doc = await db.collection('coachForms').doc(uid).get();
    if (!doc.exists) throw new NotFoundError("Form not found.");
    return doc.data();
  }

  async approveFormManpower(uid, approverData) {
    const railwaySupervisor = approverData;
    const formDocRef = db.collection('coachForms').doc(uid);
    const doc = await formDocRef.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");

    const formData = doc.data();
    if (formData.submittedTo.railwayEmployeeId !== railwaySupervisor.uid) {
      throw new ForbiddenError("You are not authorized to approve this form.");
    }

    if (formData.status === 'SUBMITTED' || formData.status === 'RE-SUBMITTED') {
      await formDocRef.update({
        status: 'APPROVED_BY_RAILWAY',
        manpowerApprovedAt: db.Timestamp()
      });
      return { message: 'Form approved for scoring.' };
    }

    throw new ValidationError(`Form status is already ${formData.status}.`);
  }

  async scoreForm(uid, scorerData, body) {
    const { workType, acwpStatus, coachEvaluationTable, railwayRemarks, railwaySignatureName, railwaySignatureDate } = body;
    const railwaySupervisor = scorerData;

    if (!workType || !acwpStatus || !coachEvaluationTable || !railwaySignatureName || !railwaySignatureDate) {
      throw new ValidationError("Work Type, ACWP Status, Evaluation Table, and Signature are required for final submission.");
    }

    const formDocRef = db.collection('coachForms').doc(uid);
    const doc = await formDocRef.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");

    const formData = doc.data();
    if (formData.submittedTo.railwayEmployeeId !== railwaySupervisor.uid) {
      throw new ForbiddenError("You are not authorized to rate this form.");
    }

    if (formData.status !== 'APPROVED_BY_RAILWAY' && formData.status !== 'SCORING_IN_PROGRESS') {
      throw new ValidationError(`Cannot score form. Status is ${formData.status}.`);
    }

    let totalPenalty = 0;
    const summary = {
      internal: { A: 0, B: 0, C: 0, D: 0 },
      external: { A: 0, B: 0, C: 0, D: 0 },
      intensive: { A: 0, B: 0, C: 0, D: 0 },
      toiletries: { Yes: 0, No: 0, NA: 0 },
      watering: { Yes: 0, No: 0, NA: 0 },
      doorsLocking: { Yes: 0, No: 0, NA: 0 },
      totalCoaches: 0
    };

    const processedEvaluationTable = coachEvaluationTable.map(coach => {
      summary.totalCoaches++;
      const internalPenalty = PENALTY_MAP[coach.internalCleaning] || 0;
      const externalPenalty = PENALTY_MAP[coach.externalCleaning] || 0;
      const intensivePenalty = PENALTY_MAP[coach.intensiveCleaning] || 0;
      if (coach.internalCleaning) summary.internal[coach.internalCleaning]++;
      if (coach.externalCleaning) summary.external[coach.externalCleaning]++;
      if (coach.intensiveCleaning) summary.intensive[coach.intensiveCleaning]++;
      if (coach.toiletries) summary.toiletries[coach.toiletries]++;
      if (coach.watering) summary.watering[coach.watering]++;
      if (coach.doorsLocking) summary.doorsLocking[coach.doorsLocking]++;
      const coachPenalty = internalPenalty + externalPenalty + intensivePenalty;
      totalPenalty += coachPenalty;
      return { ...coach, penalty: coachPenalty };
    });

    await formDocRef.update({
      status: 'SCORED',
      scoringInProgress: false,
      ratingDetails: {
        workType,
        acwpStatus,
        coachEvaluationTable: processedEvaluationTable,
        totalPenalty,
        summary
      },
      railwaySignature: {
        name: railwaySignatureName || railwaySupervisor.fullName,
        date: railwaySignatureDate || new Date().toISOString()
      },
      railwayRemarks: railwayRemarks || null,
      ratedAt: db.Timestamp()
    });

    return { message: 'Form successfully scored and sent to contractor.' };
  }

  async acceptRating(uid, userData) {
    const contractorSupervisor = userData;
    const formDocRef = db.collection('coachForms').doc(uid);
    const doc = await formDocRef.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");

    if (doc.data().submittedById !== contractorSupervisor.uid) {
      throw new ForbiddenError("You are not authorized to accept this rating.");
    }

    const currentStatus = doc.data().status;
    if (currentStatus === 'LOCKED' || currentStatus === 'AUTO-APPROVED') {
      throw new ValidationError("This his form is already locked.");
    }
    if (currentStatus !== 'SCORED') {
      throw new ValidationError(`Cannot accept rating. Form status is ${currentStatus}`);
    }

    await formDocRef.update({
      status: 'LOCKED',
      completedAt: db.Timestamp()
    });

    return { message: 'Rating accepted. Form is now locked.' };
  }

  async rejectForm(uid, rejectorData) {
    const railwaySupervisor = rejectorData;
    const formDocRef = db.collection('coachForms').doc(uid);
    const doc = await formDocRef.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");

    if (doc.data().submittedTo.railwayEmployeeId !== railwaySupervisor.uid) {
      throw new ForbiddenError("You are not authorized to reject this form.");
    }

    const currentStatus = doc.data().status;
    if (currentStatus !== 'SUBMITTED' && currentStatus !== 'RE-SUBMITTED' && currentStatus !== 'APPROVED_BY_RAILWAY' && currentStatus !== 'SCORING_IN_PROGRESS') {
      throw new ValidationError(`Cannot reject a form with status: ${currentStatus}`);
    }

    await formDocRef.update({
      status: 'REJECTED_BY_RAILWAY',
      rejectionComments: rejectorData.rejectionComments || null,
      rejectedAt: db.Timestamp()
    });

    return { message: 'Form successfully rejected.' };
  }
}

export const coachFormService = new CoachFormService();
