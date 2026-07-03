import { db, admin } from '../database/index.js';
import { ValidationError, ForbiddenError } from '../errors/index.js';
import config from '../config/index.js';

class DashboardService {
  async getDashboardStats(requesterData) {
    const { role, userType, zone: userZone, division: userDiv } = requesterData;
    const userRole = (role || '').trim().toLowerCase();

    const [userSnap, entitySnap, trainSnap, contractSnap] = await Promise.all([
      db.collection('users').limit(config.pagination.defaultLimit).get(),
      db.collection('entities').limit(config.pagination.defaultLimit).get(),
      db.collection('trains').limit(config.pagination.defaultLimit).get(),
      db.collection('contracts').limit(config.pagination.defaultLimit).get()
    ]);

    const stats = {
      user: { total: 0, approved: 0, pending: 0, draft: 0, railway: 0, contractor: 0 },
      entity: { total: 0, approved: 0, pending: 0, draft: 0 },
      train: { total: 0, active: 0, inactive: 0, draft: 0 }
    };

    userSnap.docs.forEach(doc => {
      const d = doc.data();
      let isVisible = false;
      if (userRole.includes('master')) { if (d.zone === userZone) isVisible = true; }
      else if (userRole.includes('admin') || userRole.includes('supervisor')) { if (d.division === userDiv) isVisible = true; }
      else if (userRole.includes('super admin')) isVisible = true;
      if (isVisible) {
        stats.user.total++;
        const s = d.status;
        if (s === 'APPROVED') stats.user.approved++;
        else if (s === 'PENDING') stats.user.pending++;
        else if (s === 'DRAFT') stats.user.draft++;
        if (d.userType === 'railway') stats.user.railway++;
        if (d.userType === 'contractor') stats.user.contractor++;
      }
    });

    entitySnap.docs.forEach(doc => {
      const d = doc.data();
      stats.entity.total++;
      if (d.status === 'APPROVED') stats.entity.approved++;
      if (d.status === 'PENDING') stats.entity.pending++;
    });

    trainSnap.docs.forEach(doc => {
      const d = doc.data();
      let isTrainVisible = false;
      if (userRole.includes('master') && d.zone === userZone) isTrainVisible = true;
      else if ((userRole.includes('admin') || userRole.includes('supervisor')) && d.division === userDiv) isTrainVisible = true;
      if (isTrainVisible) {
        stats.train.total++;
        if (d.status === 'ACTIVE' || d.status === 'active') stats.train.active++;
        else stats.train.inactive++;
      }
    });

    return {
      systemOverview: {
        railwayEmployees: stats.user.railway,
        contractorEmployees: stats.user.contractor,
        totalRegisteredEntities: stats.entity.total,
        activeContracts: contractSnap.docs.filter(c => c.data().status === 'ACTIVE').length,
        totalFormsProcessed: 0
      },
      userOverview: stats.user,
      entityOverview: stats.entity,
      trainOverview: stats.train
    };
  }

  async getRailwayDashboardStats(requesterData) {
    const { uid: userId, role, division: userDivision, entityId: userEntityId } = requesterData;

    const [divisionsSnap, depotsSnap, usersSnap, companiesSnap, contractsSnap, formsSnap] = await Promise.all([
      db.collection("divisions").limit(config.pagination.defaultLimit).get(),
      db.collection("depots").limit(config.pagination.defaultLimit).get(),
      db.collection("users").limit(config.pagination.defaultLimit).get(),
      db.collection("companies").limit(config.pagination.defaultLimit).get(),
      db.collection("contracts").limit(config.pagination.defaultLimit).get(),
      db.collection("forms_processed").limit(config.pagination.defaultLimit).get()
    ]);

    const allUsers = usersSnap.docs.map(d => ({ id: d.id, ...d.data() }));
    const allContracts = contractsSnap.docs.map(d => ({ id: d.id, ...d.data() }));
    const allDepots = depotsSnap.docs.map(d => ({ id: d.id, ...d.data() }));
    const allForms = formsSnap.docs.map(d => ({ id: d.id, ...d.data() }));

    let stats = {
      divisions: 0, depots: 0, railwayEmployees: 0, contractorEmployees: 0,
      registeredEntities: 0, activeContracts: 0, totalFormProcessed: allForms.length || 0
    };

    const normalizedRole = role ? role.toLowerCase() : "";

    if (normalizedRole === 'admin') {
      stats.divisions = divisionsSnap.size;
      stats.depots = depotsSnap.size;
      stats.registeredEntities = companiesSnap.size;
      stats.railwayEmployees = allUsers.filter(u => u.userType === 'railway' || u.role === 'Railway Supervisor').length;
      stats.contractorEmployees = allUsers.filter(u => u.userType === 'contractor').length;
      stats.activeContracts = allContracts.filter(c => c.status === 'Active' || c.status === 'active').length;
    } else if (normalizedRole.includes('railway') || normalizedRole.includes('supervisor')) {
      const assignedDiv = userDivision;
      stats.divisions = assignedDiv ? 1 : 0;
      stats.depots = allDepots.filter(d => d.division === assignedDiv).length;
      stats.railwayEmployees = allUsers.filter(u => u.division === assignedDiv && (u.userType === 'railway' || u.role === 'Railway Supervisor')).length;
      stats.contractorEmployees = allUsers.filter(u => u.division === assignedDiv && u.userType === 'contractor').length;
      stats.activeContracts = allContracts.filter(c => c.division === assignedDiv && (c.status === 'Active' || c.status === 'active')).length;
      stats.totalFormProcessed = allForms.filter(f => f.division === assignedDiv).length;
      stats.registeredEntities = [...new Set(allContracts.filter(c => c.division === assignedDiv).map(c => c.entityId))].length;
    } else if (normalizedRole.includes('company')) {
      const entityId = userEntityId;
      stats.registeredEntities = 1;
      stats.contractorEmployees = allUsers.filter(u => u.entityId === entityId).length;
      stats.activeContracts = allContracts.filter(c => c.entityId === entityId && (c.status === 'Active' || c.status === 'active')).length;
      stats.totalFormProcessed = allForms.filter(f => f.entityId === entityId).length;
      const myContracts = allContracts.filter(c => c.entityId === entityId);
      stats.divisions = [...new Set(myContracts.map(c => c.division))].length;
      stats.depots = [...new Set(myContracts.map(c => c.depot))].length;
    }

    return { success: true, data: stats };
  }

  async getUserStats(requesterData) {
    const snapshot = await db.collection('users').limit(config.pagination.defaultLimit).get();
    const users = snapshot.docs.map(d => d.data());
    return {
      total: users.length,
      approved: users.filter(u => u.status === 'APPROVED').length,
      pending: users.filter(u => u.status === 'PENDING').length,
      railway: users.filter(u => u.userType === 'railway').length,
      contractor: users.filter(u => u.userType === 'contractor').length
    };
  }

  async getTrainStats(requesterData) {
    const snapshot = await db.collection('trains').limit(config.pagination.defaultLimit).get();
    const trains = snapshot.docs.map(d => d.data());
    return {
      total: trains.length,
      active: trains.filter(t => t.status === 'ACTIVE' || t.status === 'active').length,
      obhsEnabled: trains.filter(t => (t.TrainApplicableFor || []).includes('OBHS')).length,
      ctsEnabled: trains.filter(t => (t.TrainApplicableFor || []).includes('CTS')).length
    };
  }

  async getSupervisorStats(requesterData) {
    const { division } = requesterData;
    const [usersSnap, formsSnap, tasksSnap] = await Promise.all([
      db.collection('users').where('division', '==', division).limit(config.pagination.defaultLimit).get(),
      db.collection('coachForms').where('division', '==', division).limit(config.pagination.defaultLimit).get(),
      db.collection('obhs_tasks').where('division', '==', division).limit(config.pagination.defaultLimit).get()
    ]);
    const users = usersSnap.docs.map(d => d.data());
    const forms = formsSnap.docs.map(d => d.data());
    const tasks = tasksSnap.docs.map(d => d.data());
    return {
      totalWorkers: users.filter(u => u.userType === 'contractor').length,
      activeForms: forms.filter(f => f.status === 'SUBMITTED' || f.status === 'APPROVED').length,
      pendingReview: tasks.filter(t => t.status === 'PENDING_REVIEW').length,
      completedToday: tasks.filter(t => t.status === 'COMPLETED').length
    };
  }

  async getActiveTrains(requesterData) {
    const snapshot = await db.collection('trains').where('status', '==', 'active').limit(config.pagination.defaultLimit).get();
    const trains = snapshot.docs.map(d => ({ uid: d.id, ...d.data() }));
    return { count: trains.length, trains };
  }

  async getActiveWorkers(requesterData) {
    const snapshot = await db.collection('users').where('userType', '==', 'contractor').where('status', '==', 'APPROVED').limit(config.pagination.defaultLimit).get();
    const workers = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    return { count: workers.length, workers };
  }

  async getAllFormsStats(requesterData) {
    const [coachSnap, premisesSnap, ctsSnap, cleaningSnap] = await Promise.all([
      db.collection('coachForms').limit(config.pagination.defaultLimit).get(),
      db.collection('premisesForms').limit(config.pagination.defaultLimit).get(),
      db.collection('ctsForms').limit(config.pagination.defaultLimit).get(),
      db.collection('cleaningForms').limit(config.pagination.defaultLimit).get()
    ]);
    return {
      coachForms: coachSnap.size,
      premisesForms: premisesSnap.size,
      ctsForms: ctsSnap.size,
      cleaningForms: cleaningSnap.size,
      total: coachSnap.size + premisesSnap.size + ctsSnap.size + cleaningSnap.size
    };
  }
}

export const dashboardService = new DashboardService();
