import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import * as v2Controller from '../controllers/v2Controller.js';

const router = express.Router();

router.get('/run-instances', verifyToken, v2Controller.listRunInstances);
router.get('/run-instances/:runInstanceId', verifyToken, v2Controller.getRunInstance);
router.get('/coach-forms', verifyToken, v2Controller.listCoachForms);
router.get('/coach-forms/:formId', verifyToken, v2Controller.getCoachForm);
router.get('/premises-forms', verifyToken, v2Controller.listPremisesForms);
router.get('/premises-forms/:formId', verifyToken, v2Controller.getPremisesForm);
router.get('/cts-forms', verifyToken, v2Controller.listCtsForms);
router.get('/cts-forms/:formId', verifyToken, v2Controller.getCtsForm);
router.get('/cleaning-forms', verifyToken, v2Controller.listCleaningForms);
router.get('/cleaning-forms/:uid', verifyToken, v2Controller.getCleaningForm);
router.get('/tasks', verifyToken, v2Controller.listTasks);
router.get('/tasks/:taskId', verifyToken, v2Controller.getTask);
router.get('/obhs', verifyToken, v2Controller.listOBHS);
router.get('/obhs/:obhsId', verifyToken, v2Controller.getOBHS);

export default router;
