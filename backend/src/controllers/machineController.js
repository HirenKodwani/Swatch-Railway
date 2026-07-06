import { machineService } from '../services/machineService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => res.status(201).json(await machineService.createMachine(req.user, req.body)));
export const list = asyncHandler(async (req, res) => res.json(await machineService.getMachines(req.query)));
export const getById = asyncHandler(async (req, res) => res.json(await machineService.getMachineById(req.params.uid)));
export const update = asyncHandler(async (req, res) => res.json(await machineService.updateMachine(req.params.uid, req.body)));
export const remove = asyncHandler(async (req, res) => res.json(await machineService.deleteMachine(req.params.uid)));
export const deploy = asyncHandler(async (req, res) => res.status(201).json(await machineService.deployMachine(req.user, req.body)));
export const returnMachine = asyncHandler(async (req, res) => res.json(await machineService.returnMachine(req.params.uid, req.user)));
export const listDeployments = asyncHandler(async (req, res) => res.json(await machineService.listDeployments(req.query)));
export const logDowntime = asyncHandler(async (req, res) => res.status(201).json(await machineService.logDowntime(req.user, req.body)));
export const resolveDowntime = asyncHandler(async (req, res) => res.json(await machineService.resolveDowntime(req.params.uid, req.body)));
export const listDowntime = asyncHandler(async (req, res) => res.json(await machineService.listDowntime(req.query)));
export const downtimeReport = asyncHandler(async (req, res) => res.json(await machineService.getDowntimeReport(req.query)));
export const scheduleMaintenance = asyncHandler(async (req, res) => res.status(201).json(await machineService.scheduleMaintenance(req.user, req.body)));
export const completeMaintenance = asyncHandler(async (req, res) => res.json(await machineService.completeMaintenance(req.params.uid, req.user, req.body)));
export const listMaintenance = asyncHandler(async (req, res) => res.json(await machineService.listMaintenance(req.query)));
