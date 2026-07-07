import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import { requirePermission, requireEntityAccess, requireStationAccess, requirePlatformAccess } from '../middleware/authorization.js';
import { PERMISSIONS } from '../permissions/roles.js';
import * as stationCleaning from '../controllers/stationCleaningController.js';

const router = Router();

// ─── Station Areas ────────────────────────────────────────────────────────────
router.post('/api/station-area/create', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREAS), requireStationAccess, stationCleaning.createStationArea);
router.get('/api/station-area/list/:stationId', verifyToken, requirePermission(PERMISSIONS.VIEW_AREAS), requireStationAccess, stationCleaning.listStationAreas);
router.get('/api/station-area/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_AREAS), requireStationAccess, stationCleaning.getStationArea);
router.put('/api/station-area/update/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREAS), requireStationAccess, stationCleaning.updateStationArea);
router.delete('/api/station-area/delete/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREAS), requireStationAccess, stationCleaning.deleteStationArea);

// ─── Station Zones ────────────────────────────────────────────────────────────
router.post('/api/station-zone/create', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREAS), requireStationAccess, stationCleaning.createStationZone);
router.get('/api/station-zone/list/:stationId', verifyToken, requirePermission(PERMISSIONS.VIEW_AREAS), requireStationAccess, stationCleaning.listStationZones);
router.get('/api/station-zone/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_AREAS), requireStationAccess, stationCleaning.getStationZone);
router.put('/api/station-zone/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREAS), requireStationAccess, stationCleaning.updateStationZone);
router.delete('/api/station-zone/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_AREAS), requireStationAccess, stationCleaning.deleteStationZone);

// ─── Contractor Mapping ───────────────────────────────────────────────────────
router.post('/api/station-contractor/map', verifyToken, requirePermission(PERMISSIONS.MANAGE_CONTRACTORS), requireStationAccess, stationCleaning.mapContractor);
router.get('/api/station-contractor/list/:stationId', verifyToken, requirePermission(PERMISSIONS.VIEW_CONTRACTORS), requireStationAccess, stationCleaning.listContractorMappings);
router.get('/api/station-contractor/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_CONTRACTORS), requireStationAccess, stationCleaning.getContractorMapping);
router.put('/api/station-contractor/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_CONTRACTORS), requireStationAccess, stationCleaning.updateContractorMapping);
router.delete('/api/station-contractor/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_CONTRACTORS), requireStationAccess, stationCleaning.deleteContractorMapping);

// ─── Schedules ────────────────────────────────────────────────────────────────
router.post('/api/station-schedule/create', verifyToken, requirePermission(PERMISSIONS.MANAGE_SCHEDULES), requireStationAccess, stationCleaning.createSchedule);
router.get('/api/station-schedule/list/:stationId', verifyToken, requirePermission(PERMISSIONS.VIEW_SCHEDULES), requireStationAccess, stationCleaning.listSchedules);
router.get('/api/station-schedule/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_SCHEDULES), requireStationAccess, stationCleaning.getSchedule);
router.put('/api/station-schedule/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_SCHEDULES), requireStationAccess, stationCleaning.updateSchedule);
router.delete('/api/station-schedule/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_SCHEDULES), requireStationAccess, stationCleaning.deleteSchedule);

// ─── Station Runs ─────────────────────────────────────────────────────────────
router.post('/api/station-runs', verifyToken, requirePermission(PERMISSIONS.MANAGE_RUNS), requireStationAccess, stationCleaning.createStationRun);
router.get('/api/station-runs', verifyToken, requirePermission(PERMISSIONS.VIEW_RUNS), requireStationAccess, stationCleaning.listStationRuns);
router.get('/api/station-runs/my-runs', verifyToken, requirePermission(PERMISSIONS.VIEW_RUNS), requireStationAccess, stationCleaning.getMyStationRuns);
router.get('/api/station-runs/worker/:workerId', verifyToken, requirePermission(PERMISSIONS.VIEW_RUNS), stationCleaning.getWorkerStationRuns);
router.get('/api/station-runs/supervisor/:supervisorId', verifyToken, requirePermission(PERMISSIONS.VIEW_RUNS), stationCleaning.getSupervisorStationRuns);
router.put('/api/station-runs/:runId', verifyToken, requirePermission(PERMISSIONS.MANAGE_RUNS), requireStationAccess, stationCleaning.updateStationRun);
router.delete('/api/station-runs/:runId', verifyToken, requirePermission(PERMISSIONS.MANAGE_RUNS), requireStationAccess, stationCleaning.deleteStationRun);

// ─── Station Tasks ────────────────────────────────────────────────────────────
router.post('/api/station-tasks/submit', verifyToken, requirePermission(PERMISSIONS.SUBMIT_TASKS), requirePlatformAccess, stationCleaning.submitStationTask);
router.get('/api/station-tasks/pending-review', verifyToken, requirePermission(PERMISSIONS.VIEW_TASKS), stationCleaning.listPendingStationTasks);
router.get('/api/station-tasks/:taskId', verifyToken, requirePermission(PERMISSIONS.VIEW_TASKS), stationCleaning.getStationTask);
router.put('/api/station-tasks/:taskId', verifyToken, requirePermission(PERMISSIONS.MANAGE_RUNS), stationCleaning.updateStationTask);
router.delete('/api/station-tasks/:taskId', verifyToken, requirePermission(PERMISSIONS.MANAGE_RUNS), stationCleaning.deleteStationTask);

// ─── Station Cleaning Forms ───────────────────────────────────────────────────
router.post('/api/station-cleaning-form/create', verifyToken, requirePermission(PERMISSIONS.SUBMIT_COACH_FORM), requireEntityAccess, requirePlatformAccess, stationCleaning.createStationCleaningForm);
router.post('/api/station-cleaning-form/submit/:uid', verifyToken, requirePermission(PERMISSIONS.SUBMIT_COACH_FORM), requirePlatformAccess, stationCleaning.submitStationCleaningForm);
router.post('/api/station-cleaning-form/approve/:uid', verifyToken, requirePermission(PERMISSIONS.APPROVE_FORM_MANPOWER), stationCleaning.approveStationCleaningForm);
router.post('/api/station-cleaning-form/reject/:uid', verifyToken, requirePermission(PERMISSIONS.REJECT_FORM), stationCleaning.rejectStationCleaningForm);
router.post('/api/station-cleaning-form/score/:uid', verifyToken, requirePermission(PERMISSIONS.SCORE_FORM), stationCleaning.scoreStationCleaningForm);
router.post('/api/station-cleaning-form/lock/:uid', verifyToken, requirePermission(PERMISSIONS.MANAGE_FORMS), stationCleaning.lockStationCleaningForm);
router.get('/api/station-cleaning-form/list', verifyToken, requirePermission(PERMISSIONS.VIEW_FORMS), stationCleaning.listStationCleaningForms);
router.get('/api/station-cleaning-form/details/:uid', verifyToken, requirePermission(PERMISSIONS.VIEW_FORMS), stationCleaning.getStationCleaningFormDetail);

// ─── Dashboard ────────────────────────────────────────────────────────────────
router.get('/api/station-dashboard', verifyToken, requirePermission(PERMISSIONS.VIEW_DASHBOARD), stationCleaning.getStationDashboard);

// ─── Pest Control ───────────────────────────────────────────────────────────
router.post('/api/station-pest-control/record', verifyToken, requirePermission(PERMISSIONS.MANAGE_PEST_CONTROL), requireEntityAccess, stationCleaning.recordPestControl);
router.get('/api/station-pest-control/list/:stationId', verifyToken, requirePermission(PERMISSIONS.VIEW_PEST_CONTROL), stationCleaning.listPestControl);
router.get('/api/station-pest-control/all', verifyToken, requirePermission(PERMISSIONS.VIEW_PEST_CONTROL), stationCleaning.listAllPestControl);
router.put('/api/station-pest-control/:uid/review', verifyToken, requirePermission(PERMISSIONS.MANAGE_PEST_CONTROL), stationCleaning.reviewPestControl);
router.get('/api/station-pest-control/report', verifyToken, requirePermission(PERMISSIONS.VIEW_PEST_CONTROL), stationCleaning.pestControlReport);

// ─── Machine / Material Deployment ──────────────────────────────────────────
router.post('/api/station-machines/deploy', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), requireEntityAccess, stationCleaning.deployMachine);
router.get('/api/station-machines/list', verifyToken, requirePermission(PERMISSIONS.VIEW_MACHINES), stationCleaning.listMachines);
router.put('/api/station-machines/:uid/return', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), stationCleaning.returnMachine);
router.put('/api/station-machines/:uid/maintenance', verifyToken, requirePermission(PERMISSIONS.MANAGE_MACHINES), stationCleaning.maintenanceMachine);
router.get('/api/station-machines/report', verifyToken, requirePermission(PERMISSIONS.VIEW_MACHINES), stationCleaning.machineReport);

// ─── Garbage Disposal ───────────────────────────────────────────────────────
router.post('/api/station-garbage/record', verifyToken, requirePermission(PERMISSIONS.MANAGE_GARBAGE), requireEntityAccess, stationCleaning.recordGarbageDisposal);
router.get('/api/station-garbage/records', verifyToken, requirePermission(PERMISSIONS.VIEW_GARBAGE), stationCleaning.listGarbageRecords);
router.get('/api/station-garbage/report', verifyToken, requirePermission(PERMISSIONS.VIEW_GARBAGE), stationCleaning.garbageReport);

export default router;
