import { Router } from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as stationCleaning from '../controllers/stationCleaningController.js';

const router = Router();

router.post('/api/station-area/create', verifyToken, stationCleaning.createStationArea);
router.get('/api/station-area/list/:stationId', verifyToken, stationCleaning.listStationAreas);
router.post('/api/station-zone/create', verifyToken, stationCleaning.createStationZone);
router.get('/api/station-zone/list/:stationId', verifyToken, stationCleaning.listStationZones);
router.post('/api/station-contractor/map', verifyToken, stationCleaning.mapContractor);
router.get('/api/station-contractor/list/:stationId', verifyToken, stationCleaning.listContractorMappings);
router.post('/api/station-schedule/create', verifyToken, stationCleaning.createSchedule);
router.get('/api/station-schedule/list/:stationId', verifyToken, stationCleaning.listSchedules);

router.post('/api/station-runs', verifyToken, stationCleaning.createStationRun);
router.get('/api/station-runs', verifyToken, stationCleaning.listStationRuns);
router.put('/api/station-runs/:runId', verifyToken, stationCleaning.updateStationRun);
router.get('/api/station-runs/my-runs', verifyToken, stationCleaning.getMyStationRuns);
router.delete('/api/station-runs/:runId', verifyToken, stationCleaning.deleteStationRun);

router.post('/api/station-tasks/submit', verifyToken, stationCleaning.submitStationTask);
router.get('/api/station-tasks/pending-review', verifyToken, stationCleaning.listPendingStationTasks);

router.post('/api/station-cleaning-form/create', verifyToken, stationCleaning.createStationCleaningForm);
router.post('/api/station-cleaning-form/submit/:uid', verifyToken, stationCleaning.submitStationCleaningForm);
router.post('/api/station-cleaning-form/approve/:uid', verifyToken, stationCleaning.approveStationCleaningForm);
router.post('/api/station-cleaning-form/reject/:uid', verifyToken, stationCleaning.rejectStationCleaningForm);
router.post('/api/station-cleaning-form/score/:uid', verifyToken, stationCleaning.scoreStationCleaningForm);
router.post('/api/station-cleaning-form/lock/:uid', verifyToken, stationCleaning.lockStationCleaningForm);
router.get('/api/station-cleaning-form/list', verifyToken, stationCleaning.listStationCleaningForms);
router.get('/api/station-cleaning-form/details/:uid', verifyToken, stationCleaning.getStationCleaningFormDetail);

router.get('/api/station-dashboard', verifyToken, stationCleaning.getStationDashboard);

// ─── Pest Control ───────────────────────────────────────────────────────────
router.post('/api/station-pest-control/record', verifyToken, stationCleaning.recordPestControl);
router.get('/api/station-pest-control/list/:stationId', verifyToken, stationCleaning.listPestControl);
router.get('/api/station-pest-control/all', verifyToken, stationCleaning.listAllPestControl);
router.put('/api/station-pest-control/:uid/review', verifyToken, stationCleaning.reviewPestControl);
router.get('/api/station-pest-control/report', verifyToken, stationCleaning.pestControlReport);

// ─── Machine / Material Deployment ──────────────────────────────────────────
router.post('/api/station-machines/deploy', verifyToken, stationCleaning.deployMachine);
router.get('/api/station-machines/list', verifyToken, stationCleaning.listMachines);
router.put('/api/station-machines/:uid/return', verifyToken, stationCleaning.returnMachine);
router.put('/api/station-machines/:uid/maintenance', verifyToken, stationCleaning.maintenanceMachine);
router.get('/api/station-machines/report', verifyToken, stationCleaning.machineReport);

// ─── Garbage Disposal ───────────────────────────────────────────────────────
router.post('/api/station-garbage/record', verifyToken, stationCleaning.recordGarbageDisposal);
router.get('/api/station-garbage/records', verifyToken, stationCleaning.listGarbageRecords);
router.get('/api/station-garbage/report', verifyToken, stationCleaning.garbageReport);

export default router;
