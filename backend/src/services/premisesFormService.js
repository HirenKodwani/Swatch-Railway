import { db } from '../database/index.js';
import { NotFoundError, ValidationError, ForbiddenError } from '../errors/index.js';
import { generateFormId } from '../utils/helpers.js';

function calculateSectionStats(items) {
  if (!items || !Array.isArray(items) || items.length === 0) {
    return { processed: [], avg: 0, avgPct: 0 };
  }

  const MAX_SCORE = 10;
  let totalAvg = 0;

  const processed = items.map(item => {
    let s1 = Number(item.score1) || 0;
    let s2 = Number(item.score2) || 0;

    if (s1 > MAX_SCORE) s1 = MAX_SCORE;
    if (s2 > MAX_SCORE) s2 = MAX_SCORE;

    const itemAvg = (s1 + s2) / 2;
    const itemPct = (itemAvg / MAX_SCORE) * 100;

    totalAvg += itemAvg;

    return {
      ...item,
      score1: s1,
      score2: s2,
      avg: parseFloat(itemAvg.toFixed(2)),
      avgPercentage: parseFloat(itemPct.toFixed(2)) + '%'
    };
  });

  const sectionAvg = totalAvg / items.length;
  const sectionAvgPct = (sectionAvg / MAX_SCORE) * 100;

  return {
    processed,
    avg: parseFloat(sectionAvg.toFixed(2)),
    avgPct: parseFloat(sectionAvgPct.toFixed(2))
  };
}

class PremisesFormService {
  async submitPremisesForm(userData, body) {
    const contractorSupervisor = userData;
    const { location, contractId, submittedTo, area, ...restBody } = body;

    if (!location || !contractId || !submittedTo) {
      throw new ValidationError("Mandatory fields missing.");
    }

    const contractDoc = await db.collection('contracts').doc(contractId).get();
    if (!contractDoc.exists) {
      throw new NotFoundError("Selected Contract not found.");
    }

    const contractData = contractDoc.data();
    const contractStatus = (contractData.status || '').toLowerCase();
    if (contractStatus !== 'active') {
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

    const cats = contractData.workCategories;
    let hasPremiseAccess = false;
    if (Array.isArray(cats)) {
      hasPremiseAccess = cats.some(c => c.toLowerCase().includes('premise'));
    } else if (typeof cats === 'string') {
      hasPremiseAccess = cats.toLowerCase().includes('premise');
    }

    if (!hasPremiseAccess) {
      throw new ForbiddenError("This Contract does not allow Premises Cleaning work.");
    }

    const areaMap = { 'GICC': 23530, 'OWS': 8630, 'NWS': 10130 };
    const cleanLoc = location.trim();
    const calculatedArea = areaMap[cleanLoc] || area || 0;

    let supervisorName = null;
    if (submittedTo.railwayEmployeeId) {
      const userDoc = await db.collection('users').doc(submittedTo.railwayEmployeeId).get();
      if (userDoc.exists) supervisorName = userDoc.data().fullName;
    }

    const entityName = contractorSupervisor.entityName || contractData.agencyName || contractData.entityName || "Unknown Agency";
    const newFormId = await generateFormId('premises', contractorSupervisor.division);

    const premisesFormData = {
      uid: newFormId,
      formId: newFormId,
      location,
      area: calculatedArea,
      contractId,
      ...restBody,
      submittedTo: { ...submittedTo, railwayEmployeeName: supervisorName },
      status: 'SUBMITTED',
      submittedById: contractorSupervisor.uid,
      submittedByName: contractorSupervisor.fullName || contractorSupervisor.name,
      submittedByZone: contractorSupervisor.zone || null,
      submittedByDivision: contractorSupervisor.division || null,
      submittedByDepot: contractorSupervisor.depot || null,
      submittedByEntityId: contractorSupervisor.entityId || null,
      submittedByEntityName: entityName,
      createdAt: db.Timestamp()
    };

    await db.collection('premisesForms').doc(newFormId).set(premisesFormData);
    return { message: 'Premises form submitted.', uid: newFormId };
  }

  async getPremisesForms(filters) {
    const { user, query } = filters;
    const { uid, role, userType, zone, division, entityId } = user;
    const { status, type } = query;

    let firestoreQuery = db.collection('premisesForms');
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
      if (!isMaster) {
        if (isAdmin) {
          firestoreQuery = firestoreQuery.where('submittedByDivision', '==', division);
        } else {
          firestoreQuery = firestoreQuery.where('submittedById', '==', uid);
        }
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
      const snapshot = await firestoreQuery.limit(200).get();
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

  async getPremisesFormById(uid) {
    if (!uid) throw new ValidationError("Form ID is required.");
    const doc = await db.collection('premisesForms').doc(uid).get();
    if (!doc.exists) throw new NotFoundError("Form not found.");
    return doc.data();
  }

  async approveManpower(user, formId) {
    const railwaySupervisor = user;
    const formDocRef = db.collection('premisesForms').doc(formId);
    const doc = await formDocRef.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");

    const formData = doc.data();
    if (formData.submittedTo.railwayEmployeeId !== railwaySupervisor.uid) {
      throw new ForbiddenError("You are not authorized to approve this form.");
    }

    if (formData.status !== 'SUBMITTED' && formData.status !== 'RE-SUBMITTED') {
      throw new ValidationError(`Form status is already ${formData.status}.`);
    }

    await formDocRef.update({
      status: 'APPROVED_BY_RAILWAY',
      manpowerApprovedAt: db.Timestamp()
    });

    return { message: 'Form approved for scoring.' };
  }

  async saveScoringDraft(user, formId, body) {
    const railwaySupervisor = user;
    const { housekeepingItems, pitLineItems, disposalItems, railwayRemarks } = body;

    const formDocRef = db.collection('premisesForms').doc(formId);
    const doc = await formDocRef.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");

    const formData = doc.data();
    if (formData.submittedTo.railwayEmployeeId !== railwaySupervisor.uid) {
      throw new ForbiddenError("You are not authorized to rate this form.");
    }

    if (formData.status !== 'APPROVED_BY_RAILWAY' && formData.status !== 'SCORING_IN_PROGRESS') {
      throw new ValidationError(`Cannot save draft. Status is ${formData.status}. Please approve manpower first.`);
    }

    const housekeeping = calculateSectionStats(housekeepingItems);
    const pitLine = calculateSectionStats(pitLineItems);
    const disposal = calculateSectionStats(disposalItems);

    const overallAverage = (housekeeping.avg + pitLine.avg + disposal.avg) / 3;
    const overallAveragePct = (housekeeping.avgPct + pitLine.avgPct + disposal.avgPct) / 3;

    await formDocRef.update({
      status: 'SCORING_IN_PROGRESS',
      ratingDetails: {
        housekeepingItems: housekeeping.processed,
        pitLineItems: pitLine.processed,
        disposalItems: disposal.processed,
        summary: {
          housekeepingAveragePct: housekeeping.avgPct + '%',
          pitLineAveragePct: pitLine.avgPct + '%',
          garbageDisposalAveragePct: disposal.avgPct + '%',
          overallAveragePct: parseFloat(overallAveragePct.toFixed(2)) + '%'
        }
      },
      railwayRemarks: railwayRemarks || null,
      scoringLastSavedAt: db.Timestamp()
    });

    return { message: 'Scoring draft saved successfully.' };
  }

  async submitScoring(user, formId, body) {
    const railwaySupervisor = user;
    const {
      housekeepingItems, pitLineItems, disposalItems,
      railwayRemarks, railwaySignatureName, railwaySignatureDate
    } = body;

    if (!housekeepingItems || !pitLineItems || !disposalItems || !railwaySignatureName) {
      throw new ValidationError("All sections and signature are required.");
    }

    const formDocRef = db.collection('premisesForms').doc(formId);
    const doc = await formDocRef.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");

    const formData = doc.data();
    if (formData.submittedTo.railwayEmployeeId !== railwaySupervisor.uid) {
      throw new ForbiddenError("Unauthorized.");
    }

    if (formData.status !== 'APPROVED_BY_RAILWAY' && formData.status !== 'SCORING_IN_PROGRESS') {
      throw new ValidationError(`Cannot score. Status: ${formData.status}`);
    }

    const housekeeping = calculateSectionStats(housekeepingItems);
    const pitLine = calculateSectionStats(pitLineItems);
    const disposal = calculateSectionStats(disposalItems);

    const overallScore = (housekeeping.avg + pitLine.avg + disposal.avg) / 3;
    const overallAveragePct = (housekeeping.avgPct + pitLine.avgPct + disposal.avgPct) / 3;

    await formDocRef.update({
      status: 'SCORED',
      scoringInProgress: false,
      ratingDetails: {
        housekeepingItems: housekeeping.processed,
        pitLineItems: pitLine.processed,
        disposalItems: disposal.processed,
        summary: {
          housekeepingAveragePct: housekeeping.avgPct.toFixed(2) + '%',
          pitLineAveragePct: pitLine.avgPct.toFixed(2) + '%',
          garbageDisposalAveragePct: disposal.avgPct.toFixed(2) + '%',
          overallAveragePct: overallAveragePct.toFixed(2) + '%',
          housekeepingScore: housekeeping.avg.toFixed(2),
          pitLineScore: pitLine.avg.toFixed(2),
          garbageDisposalScore: disposal.avg.toFixed(2),
          overallScore: overallScore.toFixed(2)
        }
      },
      railwaySignature: { name: railwaySignatureName, date: railwaySignatureDate || new Date().toISOString() },
      railwayRemarks: railwayRemarks || null,
      ratedAt: db.Timestamp()
    });

    return { message: 'Form successfully scored.' };
  }

  async acceptRating(user, formId) {
    const contractorSupervisor = user;
    const formDocRef = db.collection('premisesForms').doc(formId);
    const doc = await formDocRef.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");

    const formData = doc.data();
    if (formData.submittedById !== contractorSupervisor.uid) {
      throw new ForbiddenError("You are not authorized to accept this rating.");
    }

    const currentStatus = formData.status;
    if (currentStatus === 'LOCKED' || currentStatus === 'AUTO-APPROVED') {
      return { message: 'Rating accepted. Form is now locked.' };
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

  async resubmit(user, formId, body) {
    const contractorSupervisor = user;
    const { location, manpower, signature, contractorRemarks, resubmitSign } = body;

    if (!resubmitSign) {
      throw new ValidationError("Resubmit Signature is required to submit the form again.");
    }

    const formDocRef = db.collection('premisesForms').doc(formId);
    const doc = await formDocRef.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");

    const formData = doc.data();
    if (formData.submittedById !== contractorSupervisor.uid) {
      throw new ForbiddenError("You are not authorized to resubmit this form.");
    }

    if (formData.status !== 'REJECTED_BY_RAILWAY') {
      throw new ValidationError(`Cannot resubmit form. Status is ${formData.status}`);
    }

    const updateData = {
      location: location || formData.location,
      manpower: manpower || formData.manpower,
      signature: signature || formData.signature,
      resubmitSignature: resubmitSign,
      status: 'RE-SUBMITTED',
      resubmittedAt: db.Timestamp()
    };

    if (contractorRemarks) {
      updateData.contractorRemarks = contractorRemarks;
    }

    await formDocRef.update(updateData);

    return { message: 'Form has been re-submitted to Railway Supervisor.' };
  }

  async rejectForm(user, formId, body) {
    const railwaySupervisor = user;
    const { rejectionComments } = body;

    if (!rejectionComments) {
      throw new ValidationError("Rejection comments are required.");
    }

    const formDocRef = db.collection('premisesForms').doc(formId);
    const doc = await formDocRef.get();
    if (!doc.exists) throw new NotFoundError("Form not found.");

    const formData = doc.data();
    if (formData.submittedTo.railwayEmployeeId !== railwaySupervisor.uid) {
      throw new ForbiddenError("You are not authorized to reject this form.");
    }

    const currentStatus = formData.status;
    const rejectableStatuses = ['SUBMITTED', 'RE-SUBMITTED', 'APPROVED_BY_RAILWAY', 'SCORING_IN_PROGRESS'];
    if (!rejectableStatuses.includes(currentStatus)) {
      throw new ValidationError(`Cannot reject a form with status: ${currentStatus}`);
    }

    await formDocRef.update({
      status: 'REJECTED_BY_RAILWAY',
      rejectionComments,
      rejectedAt: db.Timestamp()
    });

    return { message: 'Form successfully rejected.' };
  }

  async getPendingScoring(user) {
    const railwaySupervisorId = user.uid;

    let firestoreQuery = db.collection('premisesForms');
    firestoreQuery = firestoreQuery.where('submittedTo.railwayEmployeeId', '==', railwaySupervisorId);
    firestoreQuery = firestoreQuery.where('status', 'in', ['APPROVED_BY_RAILWAY', 'SCORING_IN_PROGRESS']);

    try {
      const snapshot = await firestoreQuery.limit(200).get();
      const formList = [];
      snapshot.forEach(doc => { formList.push(doc.data()); });
      formList.sort((a, b) => {
        const dateA = a.createdAt ? (a.createdAt.toDate ? a.createdAt.toDate() : new Date(a.createdAt)) : new Date(0);
        const dateB = b.createdAt ? (b.createdAt.toDate ? b.createdAt.toDate() : new Date(b.createdAt)) : new Date(0);
        return dateB - dateA;
      });
      return { count: formList.length, forms: formList };
    } catch (error) {
      if (error.code === 'FAILED_PRECONDITION') {
        throw new ValidationError('Index Missing. Check Firebase Console.');
      }
      throw error;
    }
  }
}

export const premisesFormService = new PremisesFormService();
