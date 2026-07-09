import { db } from '../database/index.js';
import { NotFoundError, ConflictError, ValidationError } from '../errors/index.js';

class ContractService {
  async createContract(creatorData, body) {
    const { contractNumber, contractName, entityId, stationIds, startDate, endDate, contractValue, workCategories, remarks, status, repName, repDesignation, repMobile, repEmail, repIdProofType, repIdProofNumber, assignedRailwayOfficials, assignedContractorUsers, scoringApplicability, billingCycle, zone, division } = body;
    const { uid, name, fullName, email, role } = creatorData;
    const creatorName = fullName || name || email || role || 'Unknown';

    if (!entityId) {
      throw new ValidationError("Please select a Contractor (Entity) to create a contract.");
    }
    if (!contractNumber || !contractName || !stationIds || !stationIds.length || !startDate || !endDate || !workCategories || !repName || !repMobile || !repEmail) {
      throw new ValidationError("Please fill all mandatory fields: Contract No, Name, Stations, Dates, Work Categories, Representative.");
    }

    if (new Date(endDate) <= new Date(startDate)) {
      throw new ValidationError("End date must be after start date.");
    }

    const entityDoc = await db.collection('entities').doc(entityId).get();
    if (!entityDoc.exists) {
      throw new NotFoundError("Selected Contractor does not exist.");
    }
    const entityData = entityDoc.data();
    if (entityData.status !== 'APPROVED') {
      throw new ValidationError("Selected Contractor is not Active/Approved.");
    }
    const entityName = entityData.companyName;

    const stationNames = [];
    let inferredZone, inferredDivision;
    if (stationIds && stationIds.length) {
      for (const sid of stationIds) {
        const snap = await db.collection('stations').doc(sid).get();
        if (snap.exists) {
          const sData = snap.data();
          stationNames.push(sData.stationName || sid);
          if (!inferredZone) inferredZone = sData.zone;
          if (!inferredDivision) inferredDivision = sData.division;
        } else throw new NotFoundError(`Station ${sid} not found.`);
      }
    }

    const duplicateSnap = await db.collection('contracts')
      .where('entityId', '==', entityId)
      .where('status', '==', 'active').get();
    if (!duplicateSnap.empty) {
      for (const doc of duplicateSnap.docs) {
        const existingStations = doc.data().stationIds || [];
        const overlap = existingStations.filter(s => stationIds.includes(s));
        if (overlap.length > 0) {
          throw new ValidationError(`This Contractor already has an active contract covering station(s): ${overlap.join(', ')}.`);
        }
      }
    }

    const representative = { name: repName, designation: repDesignation || null, mobile: repMobile, email: repEmail, idProofType: repIdProofType || null, idProofNumber: repIdProofNumber || null };

    const startMs = new Date(startDate).getTime();
    const endMs = new Date(endDate).getTime();
    const durationDays = Math.ceil((endMs - startMs) / (1000 * 60 * 60 * 24));

    const docRef = db.collection('contracts').doc();
    await docRef.set({
      uid: docRef.id,
      contractNumber,
      contractName,
      entityId,
      entityName,
      stationIds,
      stationNames,
      startDate,
      endDate,
      contractDuration: `${durationDays} days`,
      contractValue: contractValue || 0,
      workCategories,
      remarks: remarks || null,
      status: status || 'active',
      representative,
      assignedRailwayOfficials: assignedRailwayOfficials || [],
      assignedContractorUsers: assignedContractorUsers || [],
      scoringApplicability: scoringApplicability || false,
      billingCycle: billingCycle || 'monthly',
      zone: zone || inferredZone || '',
      division: division || inferredDivision || '',
      createdAt: db.Timestamp(),
      createdBy: uid,
      createdByName: creatorName
    });

    return { message: 'Contract created successfully', uid: docRef.id };
  }

  async updateContract(editorData, uid, updates) {
    const { uid: userId, name, fullName, email, role } = editorData;
    const editorName = fullName || name || email || role || 'Unknown';

    const docRef = db.collection('contracts').doc(uid);
    const doc = await docRef.get();
    if (!doc.exists) {
      throw new NotFoundError("Contract not found.");
    }

    const updateData = { ...updates };
    updateData.updatedBy = userId;
    updateData.updatedByName = editorName;
    updateData.updatedAt = new Date().toISOString();
    if (!updateData.status || (updateData.status !== 'APPROVED' && updateData.status !== 'REJECTED')) {
      updateData.status = 'PENDING';
    }

    await docRef.update(updateData);
    return { message: 'Contract updated successfully', updates: updateData };
  }

  async getContracts(requesterData, query) {
    const { status, stationId, entityId } = query;
    const { userType, zone: userZone, division: userDivision, role } = requesterData;
    const userRole = (role || "").trim().toLowerCase().replace(/_/g, " ");

    let firestoreQuery = db.collection('contracts');

    if (userType === 'railway') {
      // All railway users can see all contracts (filtered by stationId if provided)
    } else if (userType === 'contractor') {
      const contractorEntityId = requesterData.entityId;
      if (!contractorEntityId) throw new ValidationError("Entity linkage missing.");
      firestoreQuery = firestoreQuery.where('entityId', '==', contractorEntityId);
    }

    if (status) firestoreQuery = firestoreQuery.where('status', '==', status);
    if (entityId && userType !== 'contractor') firestoreQuery = firestoreQuery.where('entityId', '==', entityId);

    const snapshot = await firestoreQuery.limit(200).get();
    if (snapshot.empty) return { count: 0, contracts: [] };

    let contracts = [];
    snapshot.forEach(doc => {
      contracts.push({ ...doc.data(), uid: doc.id });
    });

    if (stationId) {
      contracts = contracts.filter(c => (c.stationIds || []).includes(stationId));
    }

    return { count: contracts.length, contracts };
  }

  async rejectContract(rejectorData, uid, reason) {
    const { uid: userId, name, fullName, email, role } = rejectorData;
    const editorName = fullName || name || email || role || 'Unknown';

    const docRef = db.collection('contracts').doc(uid);
    const doc = await docRef.get();
    if (!doc.exists) {
      throw new NotFoundError("Contract not found.");
    }

    const updateData = {
      status: 'REJECTED',
      rejectionReason: reason || null,
      rejectedBy: userId,
      rejectedByName: editorName,
      rejectedAt: new Date().toISOString(),
      updatedBy: userId,
      updatedByName: editorName,
      updatedAt: new Date().toISOString()
    };

    await docRef.update(updateData);
    return { message: 'Contract rejected successfully', uid, status: 'REJECTED' };
  }

  async getContractByUid(uid) {
    if (!uid) throw new ValidationError("Contract ID (UID) is required.");
    const docRef = db.collection('contracts').doc(uid);
    const doc = await docRef.get();
    if (!doc.exists) throw new NotFoundError("Contract not found.");
    return doc.data();
  }

  async getContractByNumber(contractNumber) {
    if (!contractNumber) throw new ValidationError("Contract Number is required.");
    const snapshot = await db.collection('contracts').where('contractNumber', '==', contractNumber).limit(1).get();
    if (snapshot.empty) throw new NotFoundError("Contract not found with this number.");
    return snapshot.docs[0].data();
  }

  async getContractsByEntity(entityId, query) {
    if (!entityId) throw new ValidationError("Entity ID is required.");
    const { status, stationId, category } = query || {};
    let firestoreQuery = db.collection('contracts').where('entityId', '==', entityId);
    if (status) firestoreQuery = firestoreQuery.where('status', '==', status);
    const snapshot = await firestoreQuery.limit(200).get();
    if (snapshot.empty) return { count: 0, contracts: [] };
    const contracts = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      let include = true;
      if (category) {
        const cats = data.workCategories;
        if (Array.isArray(cats)) {
          if (!cats.some(c => c.toLowerCase().includes(category.toLowerCase()))) include = false;
        } else if (typeof cats === 'string') {
          if (!cats.toLowerCase().includes(category.toLowerCase())) include = false;
        } else {
          include = false;
        }
      }
      if (include) {
        contracts.push(data);
      }
    });
    return { count: contracts.length, contracts };
  }
}

export const contractService = new ContractService();
