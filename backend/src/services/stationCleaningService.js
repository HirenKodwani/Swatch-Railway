import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError, ForbiddenError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

class StationCleaningService {

  _resolveStationId(requestedStationId, user) {
    const role = (user?.role || '').toUpperCase();
    if (user?.stationId && role === 'RAILWAY_SUPERVISOR') {
      return user.stationId;
    }
    return requestedStationId;
  }

  _resolveAreaId(requestedAreaId, user) {
    const role = (user?.role || '').toUpperCase();
    return requestedAreaId;
  }

  _isMasterOrAdmin(user) {
    const role = (user?.role || '').toUpperCase();
    return ['SUPER_ADMIN', 'COMPANY_MASTER', 'RAILWAY_MASTER', 'ADMIN'].includes(role);
  }

  _scopeByContract(query, user, stationField = 'stationId') {
    if (this._isMasterOrAdmin(user)) return query;
    const userStations = user?.stations;
    if (userStations && Array.isArray(userStations) && userStations.length > 0) {
      return query.where(stationField, 'in', userStations);
    }
    return query;
  }

  _scopeByDivision(query, user, divisionField = 'division') {
    const role = (user?.role || '').toUpperCase();
    if (this._isMasterOrAdmin(user)) return query;
    if (user?.division) {
      return query.where(divisionField, '==', user.division);
    }
    return query;
  }

  _scopeByArea(query, user, field = 'areaId') {
    return query;
  }

  _scopeByEntity(query, user, entityField = 'entityId') {
    if (user?.userType === 'contractor' && user?.entityId) {
      return query.where(entityField, '==', user.entityId);
    }
    return query;
  }

  _scopeByContractId(query, user, contractField = 'contractId') {
    if (this._isMasterOrAdmin(user)) return query;
    if (user?.contractId) {
      return query.where(contractField, '==', user.contractId);
    }
    return query;
  }

  _verifyStationAccess(task, user) {
    const role = (user?.role || '').toUpperCase();
    const userStationId = user?.stationId;
    if (userStationId && task.stationId && task.stationId !== userStationId) {
      throw new ForbiddenError('You can only access tasks in your assigned station');
    }
  }

  // ─── Station Areas ──────────────────────────────────────────────────────────
  async createStationArea(body) {
    const { stationId, areaName } = body;
    if (!stationId || !areaName) throw new ValidationError('stationId and areaName are required');
    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');
    const ref = db.collection('stationAreas').doc();
    const data = {
      uid: ref.id, stationId,
      stationName: stationDoc.data().stationName || '',
      areaName, name: areaName, areaType: body.areaType || 'Other',
      cleaningFrequency: body.cleaningFrequency || 'daily',
      priority: body.priority || 3,
      status: 'active',
      platformId: body.platformId || null,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Station area created', uid: ref.id, data };
  }

  async updateStationArea(uid, body) {
    const ref = db.collection('stationAreas').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Station area not found');
    const updates = { ...body, updatedAt: new Date().toISOString() };
    delete updates.uid;
    await ref.update(updates);
    return { message: 'Station area updated', uid };
  }

  async deleteStationArea(uid) {
    const ref = db.collection('stationAreas').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Station area not found');
    await ref.update({ status: 'inactive', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Station area deleted', uid };
  }

  async listStationAreas(stationId, user) {
    if (!stationId) throw new ValidationError('stationId is required');
    const snapshot = await db.collection('stationAreas')
      .where('stationId', '==', stationId)
      .where('status', '==', 'active').get();
    const areas = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    areas.sort((a, b) => (a.areaName || '').localeCompare(b.areaName || ''));
    return { count: areas.length, areas };
  }

  async getStationArea(uid) {
    const doc = await db.collection('stationAreas').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Station area not found');
    return { id: doc.id, ...doc.data() };
  }

  // ─── Station Zones ──────────────────────────────────────────────────────────
  async createStationZone(body) {
    const { stationId } = body;
    const zoneName = body.zoneName || body.name;
    if (!stationId || !zoneName) throw new ValidationError('stationId and zoneName are required');
    const ref = db.collection('stationZones').doc();
    const data = {
      uid: ref.id, stationId, areaId: body.areaId || null,
      zoneName, name: zoneName, zoneType: body.zoneType || 'Other',
      description: body.description || '',
      status: 'active',
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Station zone created', uid: ref.id, data };
  }

  async listStationZones(stationId, areaId, user) {
    if (!stationId) throw new ValidationError('stationId is required');
    let q = db.collection('stationZones').where('stationId', '==', stationId).where('status', '==', 'active');
    if (areaId) q = q.where('areaId', '==', areaId);
    const snapshot = await q.get();
    let zones = snapshot.docs.map(d => {
      const data = d.data();
      const zName = data.zoneName || data.name || '';
      return {
        id: d.id,
        uid: d.id,
        ...data,
        name: zName,
        zoneName: zName
      };
    });

    if (zones.length === 0 && areaId) {
      const areaDoc = await db.collection('stationAreas').doc(areaId).get();
      if (areaDoc.exists && (areaDoc.data().areaName || areaDoc.data().name || '').toLowerCase().includes('platform')) {
        zones = [
          { id: `${areaId}-toilet`, uid: `${areaId}-toilet`, stationId, areaId, name: 'Toilet', zoneName: 'Toilet', status: 'active', createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
          { id: `${areaId}-waiting`, uid: `${areaId}-waiting`, stationId, areaId, name: 'Waiting Room', zoneName: 'Waiting Room', status: 'active', createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
          { id: `${areaId}-concourse`, uid: `${areaId}-concourse`, stationId, areaId, name: 'Concourse', zoneName: 'Concourse', status: 'active', createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
          { id: `${areaId}-track`, uid: `${areaId}-track`, stationId, areaId, name: 'Track Side', zoneName: 'Track Side', status: 'active', createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() }
        ];
      }
    }

    return { count: zones.length, zones };
  }

  async getStationZone(uid) {
    const doc = await db.collection('stationZones').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Station zone not found');
    const data = doc.data();
    const zName = data.zoneName || data.name || '';
    return {
      id: doc.id,
      uid: doc.id,
      ...data,
      name: zName,
      zoneName: zName
    };
  }

  async updateStationZone(uid, body) {
    const ref = db.collection('stationZones').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Station zone not found');
    const zoneName = body.zoneName || body.name;
    const updates = { ...body, updatedAt: new Date().toISOString() };
    if (zoneName) {
      updates.zoneName = zoneName;
      updates.name = zoneName;
    }
    delete updates.uid;
    await ref.update(updates);
    return { message: 'Station zone updated', uid };
  }

  async deleteStationZone(uid) {
    const ref = db.collection('stationZones').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Station zone not found');
    await ref.update({ status: 'inactive', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Station zone deleted', uid };
  }

  // ─── Contractor Mappings ────────────────────────────────────────────────────
  async mapContractor(body) {
    const { stationId, contractorId } = body;
    if (!stationId || !contractorId) throw new ValidationError('stationId and contractorId are required');
    const ref = db.collection('stationContractorMappings').doc();
    const data = {
      uid: ref.id, stationId, contractorId,
      contractId: body.contractId || null,
      status: 'active',
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Contractor mapped', uid: ref.id, data };
  }

  async listContractorMappings(stationId, user) {
    if (!stationId) throw new ValidationError('stationId is required');
    const snapshot = await db.collection('stationContractorMappings')
      .where('stationId', '==', stationId).where('status', '==', 'active').get();
    const mappings = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    return { count: mappings.length, mappings };
  }

  async getContractorMapping(uid) {
    const doc = await db.collection('stationContractorMappings').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Contractor mapping not found');
    return { id: doc.id, ...doc.data() };
  }

  async updateContractorMapping(uid, body) {
    const ref = db.collection('stationContractorMappings').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Contractor mapping not found');
    await ref.update({ ...body, updatedAt: new Date().toISOString() });
    return { message: 'Contractor mapping updated', uid };
  }

  async deleteContractorMapping(uid) {
    const ref = db.collection('stationContractorMappings').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Contractor mapping not found');
    await ref.update({ status: 'inactive', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Contractor mapping deleted', uid };
  }

  // ─── Schedules ──────────────────────────────────────────────────────────────
  async createSchedule(body) {
    const { stationId, scheduleName } = body;
    if (!stationId) throw new ValidationError('stationId is required');
    const ref = db.collection('stationSchedules').doc();
    const data = {
      uid: ref.id, stationId,
      scheduleName: scheduleName || 'Schedule',
      shiftType: body.shiftType || 'morning',
      startTime: body.startTime || '06:00',
      endTime: body.endTime || '14:00',
      status: 'active',
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Schedule created', uid: ref.id, data };
  }

  async listSchedules(stationId, user) {
    if (!stationId) throw new ValidationError('stationId is required');
    const snapshot = await db.collection('stationSchedules')
      .where('stationId', '==', stationId).where('status', '==', 'active').get();
    const schedules = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    return { count: schedules.length, schedules };
  }

  async getSchedule(uid) {
    const doc = await db.collection('stationSchedules').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Schedule not found');
    return { id: doc.id, ...doc.data() };
  }

  async updateSchedule(uid, body) {
    const ref = db.collection('stationSchedules').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Schedule not found');
    await ref.update({ ...body, updatedAt: new Date().toISOString() });
    return { message: 'Schedule updated', uid };
  }

  async deleteSchedule(uid) {
    const ref = db.collection('stationSchedules').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Schedule not found');
    await ref.update({ status: 'inactive', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Schedule deleted', uid };
  }

  _shiftDefaultTime(shift) {
    const s = (shift || '').toLowerCase();
    if (s.includes('morning')) return '08:00';
    if (s.includes('afternoon')) return '12:00';
    if (s.includes('evening')) return '16:00';
    if (s.includes('night')) return '20:00';
    return '08:00';
  }

  async _createPlatformTasks(platforms, runData, user) {
    const batch = admin.firestore().batch();
    const tasks = [];
    const now = new Date().toISOString();
    const scheduledTime = this._shiftDefaultTime(runData.shift);
    for (const plat of (platforms || [])) {
      if (!runData.supervisorId && !user?.uid) continue;
      const taskRef = db.collection('cleaningTasks').doc();
      const areaId = plat.areaId || `platform_${plat.platformNumber || 'unknown'}_${runData.stationId}`;
      const areaName = plat.areaName || (plat.platformNumber ? `Platform ${plat.platformNumber}` : 'Station Area');
      const taskData = {
        uid: taskRef.id,
        stationId: runData.stationId,
        stationName: runData.stationName || '',
        platformId: plat.platformNumber || '',
        areaId,
        areaName,
        workerId: runData.supervisorId || (user && user.uid) || null,
        workerName: runData.supervisorName || '',
        supervisorId: runData.supervisorId || (user && user.uid) || null,
        activityType: 'station_cleaning',
        frequency: runData.frequency || 'daily',
        scheduledDate: runData.date || runData.runDate,
        scheduledTime,
        priority: 3,
        shift: runData.shift || 'morning',
        status: 'pending',
        runInstanceId: runData.runInstanceId || '',
        createdBy: user && user.uid,
        createdAt: now,
        updatedAt: now
      };
      batch.set(taskRef, taskData);
      tasks.push(taskData);
    }
    if (tasks.length > 0) await batch.commit();
    return tasks;
  }

  // ─── Station Runs ───────────────────────────────────────────────────────────
  async createStationRun(body, user) {
    const { stationId } = body;
    if (!stationId) throw new ValidationError('stationId is required');
    const ref = db.collection('stationRuns').doc();
    
    const runDate = body.date || body.runDate || new Date().toISOString().split('T')[0];
    const shiftType = body.shift || body.shiftType || 'morning';
    const runInstanceId = body.runInstanceId || ref.id;

    const data = {
      ...body,
      uid: ref.id,
      runInstanceId,
      stationId,
      stationName: body.stationName || '',
      date: runDate,
      runDate,
      shift: shiftType,
      shiftType: shiftType.toLowerCase(),
      platforms: body.platforms || [],
      supervisorId: body.supervisorId || (user && user.uid) || null,
      contractorId: body.contractorId || null,
      contractId: body.contractId || (user && user.contractId) || null,
      status: body.status || 'active',
      createdBy: user && user.uid,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    await ref.set(data);

    const tasks = await this._createPlatformTasks(body.platforms, data, user);

    return { message: 'Station run created', uid: ref.id, data, tasksCreated: tasks.length };
  }

  async listStationRuns(query, user) {
    const { stationId } = query;
    let q = db.collection('stationRuns').limit(200);
    q = this._scopeByContract(q, user, 'stationId');
    q = this._scopeByContractId(q, user);
    if (stationId) q = q.where('stationId', '==', stationId);
    const snapshot = await q.get();
    const runs = snapshot.docs
      .filter(d => d.data().status !== 'deleted')
      .map(d => ({ id: d.id, ...d.data() }));
    return { count: runs.length, runs };
  }

  async updateStationRun(runId, body) {
    const ref = db.collection('stationRuns').doc(runId);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Station run not found');
    
    const runDate = body.date || body.runDate || new Date().toISOString().split('T')[0];
    const shiftType = body.shift || body.shiftType || 'morning';

    await ref.update({
      ...body,
      date: runDate,
      runDate,
      shift: shiftType,
      shiftType: shiftType.toLowerCase(),
      updatedAt: new Date().toISOString()
    });
    return { message: 'Station run updated', runId };
  }

  async getMyStationRuns(userId) {
    const supervisorSnap = await db.collection('stationRuns')
      .where('supervisorId', '==', userId).limit(100).get();
    
    const runs = [];
    supervisorSnap.forEach(d => {
      const data = d.data();
      if (data.status !== 'deleted') {
        runs.push({ id: d.id, ...data });
      }
    });
    return { count: runs.length, runs };
  }

  async deleteStationRun(runId) {
    const ref = db.collection('stationRuns').doc(runId);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Station run not found');
    await ref.update({ status: 'deleted', deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Station run deleted', runId };
  }

  async getWorkerStationRuns(workerId, user) {
    let q = db.collection('stationRuns').limit(300);
    q = this._scopeByContractId(q, user);
    const snapshot = await q.get();
    const runs = [];
    snapshot.forEach(d => {
      const runData = d.data();
      if (runData.status === 'deleted') return;
      if (runData.platforms && Array.isArray(runData.platforms)) {
        const workerPlatforms = runData.platforms.filter(p => p.janitorId === workerId);
        if (workerPlatforms.length > 0) {
          runs.push({ id: d.id, ...runData, platforms: workerPlatforms });
        }
      }
    });
    return { count: runs.length, runs };
  }

  async getSupervisorStationRuns(supervisorId, user) {
    let q = db.collection('stationRuns')
      .where('supervisorId', '==', supervisorId).limit(100);
    q = this._scopeByContractId(q, user);
    const snapshot = await q.get();
    const runs = snapshot.docs
      .filter(d => d.data().status !== 'deleted')
      .map(d => ({ id: d.id, ...d.data() }));
    return { count: runs.length, runs };
  }

  async completePlatform(runId, body, user) {
    const ref = db.collection('stationRuns').doc(runId);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Station run not found');

    const runData = doc.data();
    if (runData.status === 'deleted') throw new NotFoundError('Station run not found');

    const platformNumber = body.platformNumber;
    const photoUrl = body.photoUrl;

    if (!platformNumber) {
      throw new Error('platformNumber is required in the body');
    }

    const platforms = runData.platforms || [];
    const platformIndex = platforms.findIndex(p => p.platformNumber === platformNumber);
    if (platformIndex === -1) {
      throw new NotFoundError('Platform not found in this run');
    }

    if (platforms[platformIndex].status === 'Completed') {
       throw new Error('Platform is already completed');
    }

    platforms[platformIndex].status = 'Completed';
    platforms[platformIndex].completedAt = new Date().toISOString();
    platforms[platformIndex].completedBy = user.uid;
    if (photoUrl) {
      platforms[platformIndex].photoUrl = photoUrl;
    }

    const allCompleted = platforms.every(p => p.status === 'Completed');
    const newStatus = allCompleted ? 'Completed' : 'In Progress';

    await ref.update({
      platforms: platforms,
      status: newStatus,
      updatedAt: new Date().toISOString()
    });

    return { message: `Platform ${platformNumber} marked complete`, runId, platformNumber: platformNumber };
  }

  // ─── Station Tasks ──────────────────────────────────────────────────────────
  // Tasks are primarily managed via taskManagementService (used by tasksV2 routes).
  // These methods provide station-task CRUD for admin use cases.

  async submitStationTask(body, user) {
    const { stationId, areaId, workerId } = body;
    const userStationId = user?.stationId;
    if (userStationId && stationId && stationId !== userStationId) {
      throw new ForbiddenError('You can only create tasks in your assigned station');
    }
    const ref = db.collection('cleaningTasks').doc();
    const data = {
      uid: ref.id, stationId, areaId: areaId || null,
      workerId: workerId || null,
      taskType: body.taskType || 'cleaning',
      status: 'pending',
      beforePhoto: body.beforePhoto || null,
      afterPhoto: body.afterPhoto || null,
      remarks: body.remarks || '',
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Task created', uid: ref.id, data };
  }

  async getStationTask(taskId, user) {
    const doc = await db.collection('cleaningTasks').doc(taskId).get();
    if (!doc.exists) throw new NotFoundError('Station task not found');
    const task = doc.data();
    this._verifyStationAccess(task, user);
    return { id: doc.id, ...task };
  }

  async updateStationTask(taskId, body, user) {
    const ref = db.collection('cleaningTasks').doc(taskId);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Station task not found');
    this._verifyStationAccess(doc.data(), user);
    await ref.update({ ...body, updatedAt: new Date().toISOString() });
    return { message: 'Station task updated', taskId };
  }

  async deleteStationTask(taskId) {
    const ref = db.collection('cleaningTasks').doc(taskId);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Station task not found');
    await ref.delete();
    return { message: 'Station task deleted', taskId };
  }

  async listPendingStationTasks(runInstanceId, user) {
    const pendingStatuses = ['completed', 'resubmitted'];
    let allTasks = [];
    const userStationId = user?.stationId || null;
    for (const status of pendingStatuses) {
      let q = db.collection('cleaningTasks').where('status', '==', status).limit(200);
      if (runInstanceId) q = q.where('runInstanceId', '==', runInstanceId);
      if (userStationId) q = q.where('stationId', '==', userStationId);
      const snapshot = await q.get();
      snapshot.forEach(d => allTasks.push({ id: d.id, ...d.data() }));
    }
    return { count: allTasks.length, tasks: allTasks };
  }

  // ─── Area-Task Frequency Mapping (SRS #2) ──────────────────────────────────
  async createAreaTaskFrequency(body) {
    const { stationId, areaId, taskTypeId, frequencyId, shift } = body;
    if (!stationId || !areaId || !taskTypeId || !frequencyId) {
      throw new ValidationError('stationId, areaId, taskTypeId, and frequencyId are required');
    }
    const ref = db.collection('areaTaskFrequencies').doc();
    const data = {
      uid: ref.id, stationId, areaId, taskTypeId, frequencyId,
      shift: shift || null,
      isActive: true,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Area-task frequency mapping created', uid: ref.id, data };
  }

  async updateAreaTaskFrequency(uid, body) {
    const ref = db.collection('areaTaskFrequencies').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Area-task frequency mapping not found');
    await ref.update({ ...body, updatedAt: new Date().toISOString() });
    return { message: 'Area-task frequency mapping updated', uid };
  }

  async deleteAreaTaskFrequency(uid) {
    const ref = db.collection('areaTaskFrequencies').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Area-task frequency mapping not found');
    await ref.update({ isActive: false, updatedAt: new Date().toISOString() });
    return { message: 'Area-task frequency mapping deactivated', uid };
  }

  async listAreaTaskFrequencies(query) {
    const { stationId, areaId } = query;
    let q = db.collection('areaTaskFrequencies').where('isActive', '==', true);
    if (stationId) q = q.where('stationId', '==', stationId);
    if (areaId) q = q.where('areaId', '==', areaId);
    const snapshot = await q.limit(200).get();
    const mappings = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    return { count: mappings.length, mappings };
  }

  // ─── Station Cleaning Forms ─────────────────────────────────────────────────
  async createStationCleaningForm(body, user) {
    const { stationId } = body;
    if (!stationId) throw new ValidationError('stationId is required');
    const ref = db.collection('stationCleaningForms').doc();
    const data = {
      uid: ref.id, stationId,
      entityId: body.entityId || null,
      contractId: body.contractId || null,
      platformId: body.platformId || null,
      shiftType: body.shiftType || 'morning',
      formDate: body.formDate || new Date().toISOString().split('T')[0],
      status: body.status || 'draft',
      createdBy: user && user.uid,
      createdByName: user && (user.fullName || user.name) || 'Unknown',
      submittedBy: user && user.uid,
      submittedByName: user && (user.fullName || user.name) || 'Unknown',
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Cleaning form created', uid: ref.id, data };
  }

  async submitStationCleaningForm(uid, body, user) {
    const ref = db.collection('stationCleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Cleaning form not found');
    const currentStatus = doc.data().status;
    const allowed = ['draft', 'rejected'];
    if (!allowed.includes(currentStatus)) {
      throw new ValidationError(`Only draft or rejected forms can be submitted. Current status: ${currentStatus}`);
    }
    await ref.update({
      ...body, status: 'submitted',
      submittedBy: user && user.uid,
      submittedByName: user && (user.fullName || user.name) || 'Unknown',
      submittedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });
    return { message: 'Cleaning form submitted', uid };
  }

  async approveStationCleaningForm(uid, user) {
    const ref = db.collection('stationCleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Cleaning form not found');
    await ref.update({
      status: 'approved',
      approvedBy: user && user.uid,
      approvedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });
    return { message: 'Cleaning form approved', uid };
  }

  async rejectStationCleaningForm(uid, reason, user) {
    const ref = db.collection('stationCleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Cleaning form not found');
    await ref.update({
      status: 'rejected',
      rejectionReason: reason || '',
      rejectedBy: user && user.uid,
      rejectedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });
    return { message: 'Cleaning form rejected', uid };
  }

  async scoreStationCleaningForm(uid, scoringData, totalScore, grade, user) {
    const ref = db.collection('stationCleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Cleaning form not found');
    await ref.update({
      scoringData: scoringData || {},
      totalScore: totalScore || 0,
      grade: grade || 'D',
      scoredBy: user && user.uid,
      scoredAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });
    return { message: 'Cleaning form scored', uid, totalScore, grade };
  }

  async lockStationCleaningForm(uid) {
    const ref = db.collection('stationCleaningForms').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Cleaning form not found');
    await ref.update({ locked: true, lockedAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    return { message: 'Cleaning form locked', uid };
  }

  async listStationCleaningForms(query, user) {
    const { stationId, status, startDate, endDate } = query;
    let q = db.collection('stationCleaningForms').limit(200);
    q = this._scopeByContract(q, user, 'stationId');
    q = this._scopeByContractId(q, user);
    if (stationId) q = q.where('stationId', '==', stationId);
    if (status) q = q.where('status', '==', status);
    const snapshot = await q.get();
    let forms = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    if (startDate) forms = forms.filter(f => (f.formDate || '') >= startDate);
    if (endDate) forms = forms.filter(f => (f.formDate || '') <= endDate);
    return { count: forms.length, forms };
  }

  async getStationCleaningFormDetail(uid) {
    const doc = await db.collection('stationCleaningForms').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Cleaning form not found');
    return { id: doc.id, ...doc.data() };
  }

  // ─── Station Dashboard ──────────────────────────────────────────────────────
  async getStationDashboard(user) {
    const now = new Date();
    const today = now.toISOString().split('T')[0];
    const stationId = user && user.stationId;
    const userStations = user?.stations;

    let tasks = [];
    let tasksQuery = db.collection('cleaningTasks')
      .where('scheduledDate', '==', today).limit(500);
    if (stationId) {
      tasksQuery = tasksQuery.where('stationId', '==', stationId);
    } else if (userStations && Array.isArray(userStations) && userStations.length > 0) {
      tasksQuery = tasksQuery.where('stationId', 'in', userStations);
    }
    const snapshot = await tasksQuery.get();
    tasks = snapshot.docs.map(d => d.data());

    const total = tasks.length;
    const completed = tasks.filter(t => t.status === 'completed' || t.status === 'approved').length;
    const pending = tasks.filter(t => t.status === 'pending').length;
    const inProgress = tasks.filter(t => t.status === 'in_progress').length;
    const approved = tasks.filter(t => t.status === 'approved').length;
    const rejected = tasks.filter(t => t.status === 'rejected').length;
    const completionRate = total > 0 ? Math.round(completed / total * 100) : 0;
    const avgScore = total > 0 ? Math.round(tasks.reduce((s, t) => s + (t.score || 0), 0) / total) : 0;

    return {
      stationId: stationId || null,
      date: today,
      totalTasks: total, completedTasks: completed,
      pendingTasks: pending, inProgressTasks: inProgress,
      approvedTasks: approved, rejectedTasks: rejected,
      completionRate, averageScore: avgScore
    };
  }

  // ─── Pest Control ───────────────────────────────────────────────────────────
  async recordPestControl(body, user) {
    const { stationId, pestType } = body;
    if (!stationId) throw new ValidationError('stationId is required');
    const ref = db.collection('pestControlRecords').doc();
    const data = {
      uid: ref.id, stationId,
      stationName: body.stationName || '',
      pestType: pestType || 'General',
      entityId: body.entityId || null,
      contractId: body.contractId || (user && user.contractId) || null,
      frequency: body.frequency || 'monthly',
      conductedDate: body.conductedDate || new Date().toISOString().split('T')[0],
      area: body.area || '',
      zone: body.zone || '',
      severity: body.severity || 'LOW',
      treatmentMethod: body.treatmentMethod || '',
      chemicalsUsed: body.chemicalsUsed || [],
      status: 'pending',
      evidence: body.evidence || [],
      beforePhoto: body.beforePhoto || '',
      afterPhoto: body.afterPhoto || '',
      remarks: body.remarks || '',
      recordedBy: user && user.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Pest control record created', uid: ref.id, data };
  }

  async listPestControl(stationId, query, user) {
    if (!stationId) throw new ValidationError('stationId is required');
    const snapshot = await db.collection('pestControlRecords')
      .where('stationId', '==', stationId).limit(200).get();
    const records = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    return records;
  }

  async listAllPestControl(query, user) {
    const { stationId, status } = query || {};
    let q = db.collection('pestControlRecords').limit(300);
    q = this._scopeByContract(q, user, 'stationId');
    q = this._scopeByContractId(q, user);
    if (stationId) q = q.where('stationId', '==', stationId);
    if (status) q = q.where('status', '==', status);
    const snapshot = await q.get();
    return snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
  }

  async reviewPestControl(uid, body, user) {
    const ref = db.collection('pestControlRecords').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Pest control record not found');
    const status = body.status || 'approved';
    await ref.update({
      status,
      reviewedBy: user && user.uid,
      reviewedAt: new Date().toISOString(),
      reviewNotes: body.notes || '',
      updatedAt: new Date().toISOString()
    });
    return { message: 'Pest control record reviewed', uid, status };
  }

  async pestControlReport(query, user) {
    const { stationId, startDate, endDate } = query || {};
    let q = db.collection('pestControlRecords').limit(300);
    q = this._scopeByContract(q, user, 'stationId');
    q = this._scopeByContractId(q, user);
    if (stationId) q = q.where('stationId', '==', stationId);
    const snapshot = await q.get();
    let records = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    if (startDate) records = records.filter(r => (r.conductedDate || '') >= startDate);
    if (endDate) records = records.filter(r => (r.conductedDate || '') <= endDate);
    return { count: records.length, records };
  }

  // ─── Machine Deployment ─────────────────────────────────────────────────────
  async deployMachine(body, user) {
    const { stationId, machineType } = body;
    if (!stationId) throw new ValidationError('stationId is required');
    const ref = db.collection('machineDeployments').doc();
    const data = {
      uid: ref.id, stationId,
      machineType: machineType || 'General',
      entityId: body.entityId || null,
      contractId: body.contractId || (user && user.contractId) || null,
      deployedDate: body.deployedDate || new Date().toISOString().split('T')[0],
      status: 'deployed',
      quantity: body.quantity || 1,
      remarks: body.remarks || '',
      deployedBy: user && user.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Machine deployed', uid: ref.id, data };
  }

  async listMachines(query, user) {
    const { stationId } = query || {};
    let q = db.collection('machineDeployments').limit(200);
    q = this._scopeByContract(q, user, 'stationId');
    q = this._scopeByContractId(q, user);
    if (stationId) q = q.where('stationId', '==', stationId);
    const snapshot = await q.get();
    return snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
  }

  async returnMachine(uid, body, user) {
    const ref = db.collection('machineDeployments').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Machine deployment not found');
    await ref.update({
      status: 'returned',
      returnedDate: body.returnedDate || new Date().toISOString().split('T')[0],
      returnedBy: user && user.uid,
      returnRemarks: body.remarks || '',
      updatedAt: new Date().toISOString()
    });
    return { message: 'Machine returned', uid };
  }

  async maintenanceMachine(uid, body, user) {
    const ref = db.collection('machineDeployments').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Machine deployment not found');
    await ref.update({
      status: 'maintenance',
      maintenanceReason: body.reason || '',
      maintenanceBy: user && user.uid,
      updatedAt: new Date().toISOString()
    });
    return { message: 'Machine sent for maintenance', uid };
  }

  async machineReport(query, user) {
    const { stationId } = query || {};
    let q = db.collection('machineDeployments').limit(300);
    q = this._scopeByContract(q, user, 'stationId');
    q = this._scopeByContractId(q, user);
    if (stationId) q = q.where('stationId', '==', stationId);
    const snapshot = await q.get();
    const records = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    return { count: records.length, records };
  }

  // ─── Garbage Disposal ───────────────────────────────────────────────────────
  async recordGarbageDisposal(body, user) {
    const { stationId } = body;
    if (!stationId) throw new ValidationError('stationId is required');
    const ref = db.collection('garbageDisposalRecords').doc();
    const data = {
      uid: ref.id, stationId,
      stationName: body.stationName || '',
      entityId: body.entityId || null,
      contractId: body.contractId || (user && user.contractId) || null,
      disposalDate: body.disposalDate || new Date().toISOString().split('T')[0],
      garbageType: body.garbageType || body.wasteType || 'General',
      wasteType: body.wasteType || '',
      quantityKg: body.quantityKg || 0,
      area: body.area || '',
      disposalMethod: body.disposalMethod || '',
      disposalAgency: body.disposalAgency || '',
      vehicleNumber: body.vehicleNumber || '',
      notes: body.notes || '',
      status: 'recorded',
      evidence: body.evidence || [],
      beforePhoto: body.beforePhoto || '',
      afterPhoto: body.afterPhoto || '',
      remarks: body.remarks || '',
      recordedBy: user && user.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Garbage disposal recorded', uid: ref.id, data };
  }

  async listGarbageRecords(query, user) {
    const { stationId, startDate, endDate, status } = query || {};
    let q = db.collection('garbageDisposalRecords').limit(300);
    q = this._scopeByContract(q, user, 'stationId');
    q = this._scopeByContractId(q, user);
    if (stationId) q = q.where('stationId', '==', stationId);
    if (status) q = q.where('status', '==', status);
    const snapshot = await q.get();
    let records = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    if (startDate) records = records.filter(r => (r.disposalDate || '') >= startDate);
    if (endDate) records = records.filter(r => (r.disposalDate || '') <= endDate);
    return records;
  }

  async approveGarbageRecord(uid, user) {
    const ref = db.collection('garbageDisposalRecords').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Garbage record not found');
    const record = doc.data();
    if (record.status !== 'recorded') throw new ValidationError(`Cannot approve. Current status: ${record.status}`);
    await ref.update({
      status: 'approved',
      reviewedBy: user && user.uid,
      reviewedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });
    return { message: 'Garbage record approved', uid };
  }

  async rejectGarbageRecord(uid, body, user) {
    const reason = body.reason || '';
    if (!reason.trim()) throw new ValidationError('Rejection reason is required');
    const ref = db.collection('garbageDisposalRecords').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Garbage record not found');
    const record = doc.data();
    if (record.status !== 'recorded') throw new ValidationError(`Cannot reject. Current status: ${record.status}`);
    await ref.update({
      status: 'rejected',
      reviewedBy: user && user.uid,
      reviewedAt: new Date().toISOString(),
      rejectionReason: reason,
      updatedAt: new Date().toISOString()
    });
    return { message: 'Garbage record rejected', uid };
  }

  async garbageReport(query, user) {
    const { stationId, startDate, endDate } = query || {};
    let q = db.collection('garbageDisposalRecords').limit(300);
    q = this._scopeByContract(q, user, 'stationId');
    q = this._scopeByContractId(q, user);
    if (stationId) q = q.where('stationId', '==', stationId);
    const snapshot = await q.get();
    let records = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    if (startDate) records = records.filter(r => (r.disposalDate || '') >= startDate);
    if (endDate) records = records.filter(r => (r.disposalDate || '') <= endDate);
    const totalKg = records.reduce((s, r) => s + (r.quantityKg || 0), 0);
    return { count: records.length, totalKg, records };
  }

  // ─── Legacy Dashboards ──────────────────────────────────────────────────────
  async getWorkerDashboard(workerId, query = {}) {
    const { date } = query;
    const targetDate = date || new Date().toISOString().split('T')[0];
    const workerDoc = await db.collection('users').doc(workerId).get();
    if (!workerDoc.exists) throw new NotFoundError('Worker not found');
    const worker = workerDoc.data();
    const tasksSnapshot = await db.collection('cleaningTasks').where('workerId', '==', workerId).where('scheduledDate', '==', targetDate).get();
    const tasks = tasksSnapshot.docs.map(d => d.data());
    const total = tasks.length;
    const completed = tasks.filter(t => t.status === 'completed' || t.status === 'approved').length;
    const inProgress = tasks.filter(t => t.status === 'in_progress').length;
    const pending = tasks.filter(t => t.status === 'pending').length;
    const approved = tasks.filter(t => t.status === 'approved').length;
    const rejected = tasks.filter(t => t.status === 'rejected').length;
    const avgScore = total > 0 ? Math.round(tasks.reduce((s, t) => s + (t.score || 0), 0) / total) : 0;
    return {
      workerId, workerName: worker.fullName || '',
      date: targetDate, totalTasks: total,
      completedTasks: completed, inProgressTasks: inProgress,
      pendingTasks: pending, approvedTasks: approved,
      rejectedTasks: rejected, averageScore: avgScore, tasks
    };
  }

  async getSupervisorDashboard(supervisorId, query = {}) {
    const { date } = query;
    const targetDate = date || new Date().toISOString().split('T')[0];
    const supDoc = await db.collection('users').doc(supervisorId).get();
    if (!supDoc.exists) throw new NotFoundError('Supervisor not found');
    const supervisor = supDoc.data();
    const stationIds = supervisor.stationId ? [supervisor.stationId] : [];
    let tasks = [];
    if (stationIds.length > 0) {
      const s = await db.collection('cleaningTasks').where('scheduledDate', '==', targetDate).get();
      tasks = s.docs.map(d => d.data()).filter(t => stationIds.includes(t.stationId));
    }
    const total = tasks.length;
    const completed = tasks.filter(t => t.status === 'completed' || t.status === 'approved').length;
    const inProgress = tasks.filter(t => t.status === 'in_progress').length;
    const pending = tasks.filter(t => t.status === 'pending').length;
    const approved = tasks.filter(t => t.status === 'approved').length;
    const rejected = tasks.filter(t => t.status === 'rejected').length;
    return {
      supervisorId, supervisorName: supervisor.fullName || '',
      date: targetDate, totalTasks: total,
      completedTasks: completed, inProgressTasks: inProgress,
      pendingTasks: pending, approvedTasks: approved, rejectedTasks: rejected
    };
  }

  async generateDailyReport(stationId, query = {}) {
    const { date } = query;
    const targetDate = date || new Date().toISOString().split('T')[0];
    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');
    const station = stationDoc.data();
    const snapshot = await db.collection('cleaningTasks').where('stationId', '==', stationId).where('scheduledDate', '==', targetDate).get();
    const tasks = snapshot.docs.map(d => d.data());
    const total = tasks.length;
    const completed = tasks.filter(t => t.status === 'completed' || t.status === 'approved').length;
    const avgScore = total > 0 ? Math.round(tasks.reduce((s, t) => s + (t.score || 0), 0) / total) : 0;
    return {
      stationId, stationName: station.stationName || '',
      date: targetDate, totalTasks: total, completedTasks: completed,
      averageScore: avgScore,
      grade: avgScore >= 90 ? 'A' : avgScore >= 75 ? 'B' : avgScore >= 60 ? 'C' : 'D',
      generatedAt: new Date().toISOString()
    };
  }

  async generateWeeklyReport(stationId, query = {}) {
    const { endDate } = query;
    const end = endDate || new Date().toISOString().split('T')[0];
    const start = new Date(end); start.setDate(start.getDate() - 6);
    const startStr = start.toISOString().split('T')[0];
    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');
    const station = stationDoc.data();
    const snapshot = await db.collection('cleaningTasks')
      .where('stationId', '==', stationId)
      .where('scheduledDate', '>=', startStr).where('scheduledDate', '<=', end).get();
    const tasks = snapshot.docs.map(d => d.data());
    const total = tasks.length;
    const completed = tasks.filter(t => t.status === 'completed' || t.status === 'approved').length;
    const avgScore = total > 0 ? Math.round(tasks.reduce((s, t) => s + (t.score || 0), 0) / total) : 0;
    return {
      stationId, stationName: station.stationName || '',
      startDate: startStr, endDate: end, totalTasks: total, completedTasks: completed,
      completionRate: total > 0 ? Math.round(completed / total * 100) : 0,
      averageScore: avgScore, grade: avgScore >= 90 ? 'A' : avgScore >= 75 ? 'B' : avgScore >= 60 ? 'C' : 'D',
      generatedAt: new Date().toISOString()
    };
  }

  async generateMonthlyReport(stationId, query = {}) {
    const { month, year } = query;
    const now = new Date();
    const m = month !== undefined ? parseInt(month) : now.getMonth() + 1;
    const y = year !== undefined ? parseInt(year) : now.getFullYear();
    const startStr = `${y}-${String(m).padStart(2, '0')}-01`;
    const lastDay = new Date(y, m, 0).getDate();
    const endStr = `${y}-${String(m).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;
    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');
    const station = stationDoc.data();
    const snapshot = await db.collection('cleaningTasks')
      .where('stationId', '==', stationId)
      .where('scheduledDate', '>=', startStr).where('scheduledDate', '<=', endStr).get();
    const tasks = snapshot.docs.map(d => d.data());
    const total = tasks.length;
    const completed = tasks.filter(t => t.status === 'completed' || t.status === 'approved').length;
    const avgScore = total > 0 ? Math.round(tasks.reduce((s, t) => s + (t.score || 0), 0) / total) : 0;
    return {
      stationId, stationName: station.stationName || '',
      month: m, year: y, period: `${startStr} to ${endStr}`,
      totalTasks: total, completedTasks: completed,
      completionRate: total > 0 ? Math.round(completed / total * 100) : 0,
      averageScore: avgScore, grade: avgScore >= 90 ? 'A' : avgScore >= 75 ? 'B' : avgScore >= 60 ? 'C' : 'D',
      generatedAt: new Date().toISOString()
    };
  }

  async getScoreTrend(stationId, query = {}) {
    const { months } = query;
    const numMonths = months ? parseInt(months) : 6;
    const now = new Date();
    const data = [];
    for (let i = numMonths - 1; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const m = d.getMonth() + 1;
      const y = d.getFullYear();
      const startStr = `${y}-${String(m).padStart(2, '0')}-01`;
      const lastDay = new Date(y, m, 0).getDate();
      const endStr = `${y}-${String(m).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;
      const snapshot = await db.collection('cleaningTasks')
        .where('stationId', '==', stationId)
        .where('scheduledDate', '>=', startStr).where('scheduledDate', '<=', endStr).get();
      const tasks = snapshot.docs.map(d => d.data());
      const withScore = tasks.filter(t => t.score);
      const avgScore = withScore.length > 0 ? Math.round(withScore.reduce((s, t) => s + (t.score || 0), 0) / withScore.length) : 0;
      data.push({ month: m, year: y, label: `${y}-${String(m).padStart(2, '0')}`, averageScore: avgScore, taskCount: tasks.length });
    }
    return { stationId, trend: data };
  }
}

export const stationCleaningService = new StationCleaningService();
