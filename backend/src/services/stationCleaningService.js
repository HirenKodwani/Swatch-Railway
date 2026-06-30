import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';

class StationCleaningService {
  async generateStationFormId(stationCode) {
    const prefix = 'SF';
    const code = (stationCode || 'STN').substring(0, 4).toUpperCase();
    const date = new Date();
    const seq = date.getFullYear().toString().slice(-2) + String(date.getMonth() + 1).padStart(2, '0');
    const counterRef = db.collection('counters').doc(`stationForm_${code}_${seq}`);
    const counter = await counterRef.get();
    let nextNum = 1;
    if (counter.exists) { nextNum = (counter.data().value || 0) + 1; }
    await counterRef.set({ value: nextNum }, { merge: true });
    return `${prefix}-${code}-${seq}-${String(nextNum).padStart(4, '0')}`;
  }

  async createStationArea(data) {
    const { stationId, name, order, description } = data;
    if (!stationId || !name) throw new ValidationError('stationId and name required');
    const ref = db.collection('stationAreas').doc();
    const area = { uid: ref.id, stationId, name, order: order || 0, description: description || '', active: true };
    await ref.set(area);
    return { message: 'Area created', uid: ref.id, area };
  }

  async listStationAreas(stationId) {
    const snapshot = await db.collection('stationAreas').where('stationId', '==', stationId).get();
    const areas = [];
    snapshot.forEach(doc => areas.push(doc.data()));
    areas.sort((a, b) => (a.order || 0) - (b.order || 0));
    return { count: areas.length, areas };
  }

  async createStationZone(data) {
    const { stationId, areaId, areaName, name, description } = data;
    if (!stationId || !areaId || !name) throw new ValidationError('stationId, areaId, name required');
    const ref = db.collection('stationZones').doc();
    const zone = { uid: ref.id, stationId, areaId, areaName: areaName || '', name, description: description || '', active: true };
    await ref.set(zone);
    return { message: 'Zone created', uid: ref.id, zone };
  }

  async listStationZones(stationId, areaId) {
    const snapshot = await db.collection('stationZones').where('stationId', '==', stationId).get();
    const zones = [];
    snapshot.forEach(doc => zones.push(doc.data()));
    const filtered = areaId ? zones.filter(z => z.areaId === areaId) : zones;
    return { count: filtered.length, zones: filtered };
  }

  async mapContractor(data) {
    const { stationId, areaId, zoneId, entityId, entityName, serviceType } = data;
    if (!stationId || !entityId) throw new ValidationError('stationId and entityId required');
    const ref = db.collection('stationContractors').doc();
    const mapping = { uid: ref.id, stationId, areaId: areaId || '', zoneId: zoneId || '', entityId, entityName: entityName || '', serviceType: serviceType || 'Station Cleaning', startDate: new Date().toISOString(), active: true };
    await ref.set(mapping);
    return { message: 'Contractor mapped', uid: ref.id };
  }

  async listContractorMappings(stationId) {
    const snapshot = await db.collection('stationContractors').where('stationId', '==', stationId).get();
    const mappings = [];
    snapshot.forEach(doc => mappings.push(doc.data()));
    return { count: mappings.length, mappings };
  }

  async createSchedule(data) {
    const { stationId, areaId, zoneId, frequency, shift, entityId, entityName, supervisorId, supervisorName, startTime, endTime, daysOfWeek } = data;
    if (!stationId) throw new ValidationError('stationId required');
    const ref = db.collection('stationSchedules').doc();
    const schedule = { uid: ref.id, stationId, areaId: areaId || '', zoneId: zoneId || '', frequency: frequency || 'daily', shift: shift || 'Morning', entityId: entityId || '', entityName: entityName || '', supervisorId: supervisorId || '', supervisorName: supervisorName || '', startTime: startTime || '', endTime: endTime || '', daysOfWeek: daysOfWeek || [], active: true, createdAt: new Date().toISOString() };
    await ref.set(schedule);
    return { message: 'Schedule created', uid: ref.id };
  }

  async listSchedules(stationId) {
    const snapshot = await db.collection('stationSchedules').where('stationId', '==', stationId).get();
    const schedules = [];
    snapshot.forEach(doc => schedules.push(doc.data()));
    return { count: schedules.length, schedules };
  }

  async createStationRun(data, user) {
    if (!data.stationId || !data.stationName || !data.date || !data.shift) {
      throw new ValidationError('Missing required fields for station run');
    }
    data.status = 'Pending';
    data.createdAt = new Date().toISOString();
    data.updatedAt = data.createdAt;
    const runId = `SCR-${data.stationName.substring(0, 3).toUpperCase()}-${Date.now()}`;
    data.runInstanceId = runId;
    await db.collection('StationCleaningRuns').doc(runId).set(data);
    return { success: true, message: 'Station Run created successfully', data };
  }

  async listStationRuns() {
    const snapshot = await db.collection('StationCleaningRuns').orderBy('createdAt', 'desc').get();
    const runs = [];
    snapshot.forEach(doc => runs.push({ id: doc.id, ...doc.data() }));
    return { success: true, data: runs };
  }

  async updateStationRun(runId, data) {
    data.updatedAt = new Date().toISOString();
    const ref = db.collection('StationCleaningRuns').doc(runId);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Station Run not found');
    await ref.update(data);
    return { success: true, message: 'Station Run updated successfully' };
  }

  async getMyStationRuns(uid) {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    const snapshot = await db.collection('StationCleaningRuns')
      .where('createdAt', '>=', thirtyDaysAgo)
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get();
    const myRuns = [];
    snapshot.forEach(doc => {
      const data = { id: doc.id, ...doc.data() };
      const platforms = data.platforms || [];
      const isAssigned = platforms.some(p => p.janitorId === uid);
      if (isAssigned) myRuns.push(data);
    });
    return { success: true, data: myRuns };
  }

  async deleteStationRun(runId) {
    const ref = db.collection('StationCleaningRuns').doc(runId);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Station Run not found');
    await ref.delete();
    return { success: true, message: 'Station Run deleted successfully' };
  }

  async submitStationTask(data) {
    if (!data.runInstanceId || !data.platformNumber) {
      throw new ValidationError('Missing runInstanceId or platformNumber');
    }
    data.status = 'Completed';
    data.submittedAt = new Date().toISOString();
    const result = await db.collection('station_tasks').add(data);
    return { success: true, message: 'Task submitted', taskId: result.id };
  }

  async listPendingStationTasks(runInstanceId) {
    let query = db.collection('station_tasks').where('status', '==', 'Completed');
    if (runInstanceId) query = query.where('runInstanceId', '==', runInstanceId);
    const snapshot = await query.get();
    const tasks = [];
    snapshot.forEach(doc => tasks.push({ id: doc.id, ...doc.data() }));
    return { success: true, count: tasks.length, data: tasks };
  }

  async createStationCleaningForm(data, user) {
    const { stationId, stationName, areaId, areaName, zoneId, zoneName, division, depot, contractId, contractNumber, cleaningDate, shift, startTime, endTime, manpowerCount, machineCount, areaCovered, areaUncleaned, garbageCollected, remarks, latitude, longitude, deviceId, gpsAddress, photos, activities } = data;
    const { uid, fullName, entityId, entityName } = user;
    if (!stationId || !division) throw new ValidationError('stationId and division required');

    const stationDoc = await db.collection('stations').doc(stationId).get();
    const stationCode = stationDoc.exists ? stationDoc.data().stationCode : 'STN';
    const formId = await this.generateStationFormId(stationCode);

    const ref = db.collection('stationCleaningForms').doc();
    const form = {
      uid: ref.id, formId, stationId, stationName: stationName || '', areaId: areaId || '', areaName: areaName || '',
      zoneId: zoneId || '', zoneName: zoneName || '', division, depot: depot || '',
      contractId: contractId || '', contractNumber: contractNumber || '',
      entityId: entityId || '', entityName: entityName || '',
      submittedBy: uid, submittedByName: fullName,
      status: 'draft',
      cleaningDate: cleaningDate || '', shift: shift || '', startTime: startTime || '', endTime: endTime || '',
      manpowerCount: manpowerCount || 0, machineCount: machineCount || 0,
      areaCovered: areaCovered || 0, areaUncleaned: areaUncleaned || 0, garbageCollected: garbageCollected || 0,
      remarks: remarks || '', latitude: latitude || 0, longitude: longitude || 0,
      deviceId: deviceId || '', gpsAddress: gpsAddress || '',
      photos: photos || [], activities: activities || [],
      auditLog: [{ action: 'CREATED', performedBy: uid, performedByName: fullName, timestamp: new Date().toISOString(), details: `Form ${formId} created` }],
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
    };
    await ref.set(form);
    return { message: 'Station cleaning form created', uid: ref.id, formId };
  }

  async submitStationCleaningForm(uid, user) {
    const ref = db.collection('stationCleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Form not found');
    const form = doc.data();
    if (form.status !== 'draft') throw new ValidationError('Only draft forms can be submitted');

    await ref.update({
      status: 'submitted', updatedAt: new Date().toISOString(),
      auditLog: db.arrayUnion({ action: 'SUBMITTED', performedBy: user.uid, performedByName: user.fullName, timestamp: new Date().toISOString(), details: 'Submitted for review' })
    });
    return { message: 'Form submitted' };
  }

  async approveStationCleaningForm(uid, user) {
    const ref = db.collection('stationCleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Form not found');
    const form = doc.data();
    if (form.status !== 'submitted') throw new ValidationError('Only submitted forms can be approved');

    await ref.update({
      status: 'approved', approvedBy: user.uid, approvedByName: user.fullName, approvedAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
      auditLog: db.arrayUnion({ action: 'APPROVED', performedBy: user.uid, performedByName: user.fullName, timestamp: new Date().toISOString(), details: `Approved by ${user.fullName}` })
    });
    return { message: 'Form approved' };
  }

  async rejectStationCleaningForm(uid, reason, user) {
    const ref = db.collection('stationCleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Form not found');
    const form = doc.data();
    if (form.status !== 'submitted') throw new ValidationError('Only submitted forms can be rejected');

    await ref.update({
      status: 'rejected', rejectedBy: user.uid, rejectedByName: user.fullName, rejectedAt: new Date().toISOString(), rejectionReason: reason || 'No reason', updatedAt: new Date().toISOString(),
      auditLog: db.arrayUnion({ action: 'REJECTED', performedBy: user.uid, performedByName: user.fullName, timestamp: new Date().toISOString(), details: `Rejected: ${reason || 'No reason'}` })
    });
    return { message: 'Form rejected' };
  }

  async scoreStationCleaningForm(uid, scoringData, totalScore, grade, user) {
    const ref = db.collection('stationCleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Form not found');
    const form = doc.data();
    if (form.status !== 'approved') throw new ValidationError('Only approved forms can be scored');

    const computedGrade = grade || (totalScore >= 90 ? 'A' : totalScore >= 80 ? 'B' : totalScore >= 70 ? 'C' : 'D');

    await ref.update({
      status: 'scored', score: totalScore, grade: computedGrade, scoringData: scoringData || { criteria: [], totalScore, grade: computedGrade },
      scoredBy: user.uid, scoredByName: user.fullName, scoringAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
      auditLog: db.arrayUnion({ action: 'SCORED', performedBy: user.uid, performedByName: user.fullName, timestamp: new Date().toISOString(), details: `Score: ${totalScore} (Grade: ${computedGrade})` })
    });
    return { message: 'Score submitted', grade: computedGrade };
  }

  async lockStationCleaningForm(uid) {
    const ref = db.collection('stationCleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Form not found');
    const form = doc.data();
    if (form.status !== 'scored') throw new ValidationError('Only scored forms can be locked');

    await ref.update({
      status: 'locked', lockedAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
    });
    return { message: 'Form locked' };
  }

  async listStationCleaningForms(query, user) {
    const { status, stationId, areaId, zoneId, division } = query;
    const { role, division: userDiv, entityId, userType } = user;
    const snapshot = await db.collection('stationCleaningForms').get();
    let forms = [];
    snapshot.forEach(doc => forms.push(doc.data()));

    if (userType === 'contractor') {
      forms = forms.filter(f => f.entityId === entityId);
    } else if (!(role || '').toLowerCase().includes('master')) {
      forms = forms.filter(f => f.division === userDiv);
    }
    if (status) forms = forms.filter(f => f.status === status);
    if (stationId) forms = forms.filter(f => f.stationId === stationId);
    if (areaId) forms = forms.filter(f => f.areaId === areaId);
    if (zoneId) forms = forms.filter(f => f.zoneId === zoneId);
    if (division) forms = forms.filter(f => f.division === division);
    forms.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
    return { count: forms.length, forms };
  }

  async getStationCleaningFormDetail(uid) {
    const doc = await db.collection('stationCleaningForms').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Form not found');
    return { form: doc.data() };
  }

  async getStationDashboard(user) {
    const { role, division: userDiv, entityId, userType } = user;
    const userRole = (role || '').toLowerCase();

    let stationQuery = db.collection('stations');
    let formQuery = db.collection('stationCleaningForms');

    if (!userRole.includes('master')) {
      stationQuery = stationQuery.where('division', '==', userDiv);
      formQuery = formQuery.where('division', '==', userDiv);
    }
    if (userType === 'contractor') {
      formQuery = formQuery.where('entityId', '==', entityId);
    }

    const [stationSnap, formSnap] = await Promise.all([stationQuery.get(), formQuery.get()]);

    let totalScore = 0, scoredCount = 0;
    let draftForms = 0, submittedForms = 0, approvedForms = 0, scoredForms = 0, lockedForms = 0, rejectedForms = 0;

    formSnap.forEach(doc => {
      const d = doc.data();
      switch (d.status) {
        case 'draft': draftForms++; break;
        case 'submitted': submittedForms++; break;
        case 'approved': approvedForms++; break;
        case 'scored': scoredForms++; totalScore += d.score || 0; scoredCount++; break;
        case 'locked': lockedForms++; totalScore += d.score || 0; scoredCount++; break;
        case 'rejected': rejectedForms++; break;
      }
    });

    return {
      totalStations: stationSnap.size,
      activeStations: stationSnap.docs.filter(d => d.data().active !== false).length,
      draftForms, submittedForms, approvedForms, scoredForms, lockedForms, rejectedForms,
      pendingReview: submittedForms,
      averageScore: scoredCount > 0 ? Math.round((totalScore / scoredCount) * 100) / 100 : 0,
    };
  }
}

  // ─── Pest Control ──────────────────────────────────────────────────────
  async recordPestControl(data, user) {
    const { stationId, stationName, area, zone, pestType, severity, treatmentMethod, chemicalsUsed, notes, evidencePhotos } = data;
    if (!stationId || !pestType || !severity) throw new ValidationError('stationId, pestType, severity are required');
    const ref = db.collection('pestControlRecords').doc();
    const record = {
      uid: ref.id, stationId, stationName: stationName || '', area: area || '', zone: zone || '',
      pestType, severity, treatmentMethod: treatmentMethod || '', chemicalsUsed: chemicalsUsed || [],
      notes: notes || '', evidencePhotos: evidencePhotos || [],
      recordedBy: user.uid, recordedByName: user.fullName || user.name || 'Unknown',
      status: 'PENDING_REVIEW', createdAt: admin.firestore.FieldValue.serverTimestamp(),
      treatedAt: null, reviewedBy: null, reviewNotes: '', reviewedAt: null
    };
    await ref.set(record);
    return { uid: ref.id, data: record };
  }

  async listPestControl(stationId, query) {
    let q = db.collection('pestControlRecords').where('stationId', '==', stationId);
    if (query.status) q = q.where('status', '==', query.status);
    if (query.pestType) q = q.where('pestType', '==', query.pestType);
    const snapshot = await q.orderBy('createdAt', 'desc').get();
    const records = [];
    snapshot.forEach(doc => records.push(doc.data()));
    return records;
  }

  async listAllPestControl(query) {
    let q = db.collection('pestControlRecords');
    if (query.status) q = q.where('status', '==', query.status);
    const snapshot = await q.orderBy('createdAt', 'desc').get();
    const records = [];
    snapshot.forEach(doc => records.push(doc.data()));
    return records;
  }

  async reviewPestControl(uid, data, user) {
    const { status, reviewNotes, treatmentDate } = data;
    if (!['APPROVED', 'REJECTED', 'FOLLOW_UP'].includes(status)) throw new ValidationError('Status must be APPROVED, REJECTED, or FOLLOW_UP');
    const update = { status, reviewNotes: reviewNotes || '', reviewedBy: user.uid, reviewedAt: admin.firestore.FieldValue.serverTimestamp() };
    if (treatmentDate) update.treatedAt = treatmentDate;
    await db.collection('pestControlRecords').doc(uid).update(update);
    return { status };
  }

  async pestControlReport(query) {
    const snapshot = await db.collection('pestControlRecords').get();
    let records = [];
    snapshot.forEach(doc => records.push(doc.data()));
    const summary = { total: records.length, pending: 0, approved: 0, rejected: 0, followUp: 0 };
    const byPestType = {};
    records.forEach(r => {
      if (r.status === 'PENDING_REVIEW') summary.pending++;
      else if (r.status === 'APPROVED') summary.approved++;
      else if (r.status === 'REJECTED') summary.rejected++;
      else if (r.status === 'FOLLOW_UP') summary.followUp++;
      byPestType[r.pestType] = (byPestType[r.pestType] || 0) + 1;
    });
    return { summary, byPestType, data: records };
  }

  // ─── Machine / Material Deployment ────────────────────────────────────
  async deployMachine(data, user) {
    const { stationId, stationName, machineName, machineType, quantity, deployedTo, deployedToName, deploymentDate, expectedReturnDate, condition, notes } = data;
    if (!stationId || !machineName || !quantity) throw new ValidationError('stationId, machineName, quantity are required');
    const ref = db.collection('machineDeployments').doc();
    const record = {
      uid: ref.id, stationId, stationName: stationName || '',
      machineName, machineType: machineType || 'General', quantity: parseInt(quantity) || 1,
      deployedTo: deployedTo || '', deployedToName: deployedToName || '',
      deployedBy: user.uid, deployedByName: user.fullName || user.name || 'Unknown',
      deploymentDate: deploymentDate || new Date().toISOString(), expectedReturnDate: expectedReturnDate || '',
      condition: condition || 'GOOD', status: 'DEPLOYED', notes: notes || '',
      returnedAt: null, returnedCondition: '', returnNotes: '', createdAt: admin.firestore.FieldValue.serverTimestamp()
    };
    await ref.set(record);
    return { uid: ref.id, data: record };
  }

  async listMachines(query) {
    let q = db.collection('machineDeployments');
    if (query.stationId) q = q.where('stationId', '==', query.stationId);
    if (query.status) q = q.where('status', '==', query.status);
    if (query.machineType) q = q.where('machineType', '==', query.machineType);
    const snapshot = await q.orderBy('createdAt', 'desc').get();
    const items = [];
    snapshot.forEach(doc => items.push(doc.data()));
    return items;
  }

  async returnMachine(uid, data, user) {
    await db.collection('machineDeployments').doc(uid).update({
      status: 'RETURNED', returnedAt: admin.firestore.FieldValue.serverTimestamp(),
      returnedCondition: data.returnedCondition || '', returnNotes: data.returnNotes || '',
      returnedBy: user.uid
    });
  }

  async maintenanceMachine(uid, data, user) {
    await db.collection('machineDeployments').doc(uid).update({
      status: 'MAINTENANCE', maintenanceNotes: data.maintenanceNotes || '',
      maintenanceDate: data.maintenanceDate || new Date().toISOString(), lastMaintenanceBy: user.uid
    });
  }

  async machineReport(query) {
    let q = db.collection('machineDeployments');
    if (query.stationId) q = q.where('stationId', '==', query.stationId);
    const snapshot = await q.get();
    const items = [];
    snapshot.forEach(doc => items.push(doc.data()));
    const summary = { total: items.length, deployed: 0, returned: 0, maintenance: 0 };
    const byType = {};
    items.forEach(i => {
      if (i.status === 'DEPLOYED') summary.deployed++;
      else if (i.status === 'RETURNED') summary.returned++;
      else if (i.status === 'MAINTENANCE') summary.maintenance++;
      byType[i.machineType] = (byType[i.machineType] || 0) + 1;
    });
    return { summary, byType, data: items };
  }

  // ─── Garbage Disposal ─────────────────────────────────────────────────
  async recordGarbageDisposal(data, user) {
    const { stationId, stationName, area, wasteType, quantityKg, disposalMethod, disposalAgency, vehicleNo, notes, evidencePhotos } = data;
    if (!stationId || !wasteType || !quantityKg) throw new ValidationError('stationId, wasteType, quantityKg are required');
    const ref = db.collection('garbageDisposalRecords').doc();
    const record = {
      uid: ref.id, stationId, stationName: stationName || '', area: area || '',
      wasteType, quantityKg: parseFloat(quantityKg) || 0, disposalMethod: disposalMethod || '',
      disposalAgency: disposalAgency || '', vehicleNo: vehicleNo || '', notes: notes || '',
      evidencePhotos: evidencePhotos || [],
      recordedBy: user.uid, recordedByName: user.fullName || user.name || 'Unknown',
      status: 'COMPLETED', createdAt: admin.firestore.FieldValue.serverTimestamp()
    };
    await ref.set(record);
    return { uid: ref.id, data: record };
  }

  async listGarbageRecords(query) {
    let q = db.collection('garbageDisposalRecords');
    if (query.stationId) q = q.where('stationId', '==', query.stationId);
    const snapshot = await q.orderBy('createdAt', 'desc').get();
    const records = [];
    snapshot.forEach(doc => records.push(doc.data()));
    return records;
  }

  async garbageReport(query) {
    let q = db.collection('garbageDisposalRecords');
    if (query.stationId) q = q.where('stationId', '==', query.stationId);
    const snapshot = await q.get();
    const records = [];
    snapshot.forEach(doc => records.push(doc.data()));
    const totalKg = records.reduce((sum, r) => sum + (r.quantityKg || 0), 0);
    const byWasteType = {};
    records.forEach(r => { byWasteType[r.wasteType] = (byWasteType[r.wasteType] || 0) + (r.quantityKg || 0); });
    return { totalRecords: records.length, totalKg, byWasteType, data: records };
  }
}

export const stationCleaningService = new StationCleaningService();
