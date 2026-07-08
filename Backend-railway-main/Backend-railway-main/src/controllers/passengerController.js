import { passengerService } from '../services/passengerService.js';
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
