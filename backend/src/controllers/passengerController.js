import { passengerService } from '../services/passengerService.js';
import { taskService } from '../services/taskService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await passengerService.addPassenger(req.user, req.body);
  res.status(201).json(result);
});

export const list = asyncHandler(async (req, res) => {
  const result = await passengerService.getPassengers(req.query);
  res.status(200).json(result);
});

export const update = asyncHandler(async (req, res) => {
  const result = await passengerService.updatePassenger(req.params.passengerId, req.user, req.body);
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await passengerService.getPassengerById(req.params.passengerId);
  res.status(200).json(result);
});

export const remove = asyncHandler(async (req, res) => {
  await passengerService.deletePassenger(req.params.passengerId);
  res.status(200).json({ message: 'Passenger deleted successfully' });
});

export const sendOtp = asyncHandler(async (req, res) => {
  const result = await passengerService.sendOtp(req.body.phone);
  res.status(200).json(result);
});

export const verifyOtp = asyncHandler(async (req, res) => {
  const { phone, otp } = req.body;
  const result = await passengerService.verifyOtp(phone, otp);
  res.status(200).json(result);
});

export const createTask = asyncHandler(async (req, res) => {
  const result = await passengerService.createPassengerTask(req.body);
  res.status(201).json(result);
});

export const getTasks = asyncHandler(async (req, res) => {
  const result = await passengerService.getPassengerTasks(req.query);
  res.status(200).json(result);
});

export const getTrainCoaches = asyncHandler(async (req, res) => {
  const result = await passengerService.getTrainCoaches(req.params.trainNo);
  res.status(200).json(result);
});

export const createEmergencyTask = asyncHandler(async (req, res) => {
  const result = await taskService.createEmergencyTask(req.user, req.body);
  res.status(201).json(result);
});
