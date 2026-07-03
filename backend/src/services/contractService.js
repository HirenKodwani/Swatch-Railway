import { db } from '../database/index.js';
import { NotFoundError, ConflictError, ValidationError } from '../errors/index.js';

class ContractService {
  async createContract(creatorData, body) {
    const { contractNumber, contractName, entityId, zone, division, depot, startDate, endDate, workCategories, remarks, status, repName, repDesignation, repMobile, repEmail, repIdProofType, repIdProofNumber } = body;
    const { uid, name, fullName, email, role } = creatorData;
    const creatorName = fullName || name || email || role || 'Unknown';

    if (!entityId) {
      throw new ValidationError("Please select a Contractor (Entity) to create a contract.");
    }
    if (!contractNumber || !contractName || !zone || !startDate || !endDate || !workCategories || !repName || !repMobile || !repEmail) {
      throw new ValidationError("Please fill all other mandatory fields (*) like Contract No, Name, Dates, etc.");
    }

    let duplicateQuery = db.collection('contracts').where('entityId', '==', entityId).where('zone', '==', zone).where('division', '==', division || null);
    if (depot) {
      duplicateQuery = duplicateQuery.where('depot', '==', depot);
    }
    const duplicateSnap = await duplicateQuery.limit(1).get();
    if (!duplicateSnap.empty) {
      const locationName = depot ? `Depot: ${depot}` : `Division: ${division}`;
      throw new ValidationError(`Restriction: This Contractor already has a contract in this ${locationName}. Same company cannot have multiple contracts in the same division/depot.`);
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

    const representative = { name: repName, designation: repDesignation || null, mobile: repMobile, email: repEmail, idProofType: repIdProofType || null, idProofNumber: repIdProofNumber || null };

    const docRef = db.collection('contracts').doc();
    await docRef.set({
      uid: docRef.id,
      contractNumber,
      contractName,
      entityId,
      entityName,
      zone,
      division: division || null,
      depot: depot || null,
      startDate,
      endDate,
      workCategories,
      remarks: remarks || null,
      status: status || 'active',
      representative,
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
    const { status, division: queryDivision, zone: queryZone, entityId } = query;
    const { userType, zone: userZone, division: userDivision, role } = requesterData;
    const userRole = (role || '').trim().toLowerCase();

    let firestoreQuery = db.collection('contracts');

    if (userType === 'railway') {
      if (userRole === 'company master' || userRole === 'super admin') {
        if (queryZone) firestoreQuery = firestoreQuery.where('zone', '==', queryZone);
        if (queryDivision) firestoreQuery = firestoreQuery.where('division', '==', queryDivision);
      } else if (userRole === 'railway master') {
        if (!userZone) throw new ValidationError("Zone missing in profile.");
        firestoreQuery = firestoreQuery.where('zone', '==', userZone);
        if (queryDivision) firestoreQuery = firestoreQuery.where('division', '==', queryDivision);
      } else if (userRole.includes('admin') || userRole.includes('supervisor')) {
        if (!userDivision) throw new ValidationError("Division missing in profile.");
        firestoreQuery = firestoreQuery.where('division', '==', userDivision);
      }
    } else if (userType === 'contractor') {
      const contractorEntityId = requesterData.entityId;
      if (!contractorEntityId) throw new ValidationError("Entity linkage missing.");
      firestoreQuery = firestoreQuery.where('entityId', '==', contractorEntityId);
    }

    if (status) firestoreQuery = firestoreQuery.where('status', '==', status);
    if (entityId && userType !== 'contractor') firestoreQuery = firestoreQuery.where('entityId', '==', entityId);

    const snapshot = await firestoreQuery.limit(200).get();
    if (snapshot.empty) return { count: 0, contracts: [] };

    const contracts = [];
    snapshot.forEach(doc => {
      contracts.push({ ...doc.data(), uid: doc.id });
    });
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
    const { division, zone, status, category } = query || {};
    let firestoreQuery = db.collection('contracts').where('entityId', '==', entityId);
    if (division) firestoreQuery = firestoreQuery.where('division', '==', division);
    if (zone) firestoreQuery = firestoreQuery.where('zone', '==', zone);
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
