import { db, admin } from '../database/index.js';
import { ValidationError, ForbiddenError } from '../errors/index.js';

class DashboardService {
  async getDashboardStats(requesterData) {
    const { role, userType, zone: userZone, division: userDiv } = requesterData;
    const userRole = (role || '').trim().toLowerCase();

    const [userSnap, entitySnap, trainSnap, contractSnap] = await Promise.all([
      db.collection('users').get(),
      db.collection('entities').get(),
      db.collection('trains').get(),
      db.collection('contracts').get()
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
      db.collection("divisions").get(),
      db.collection("depots").get(),
      db.collection("users").get(),
      db.collection("companies").get(),
      db.collection("contracts").get(),
      db.collection("forms_processed").get()
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
}

export const dashboardService = new DashboardService();
