import { taskService } from '../services/taskService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const list = asyncHandler(async (req, res) => {
  const result = await taskService.getTasks({ user: req.user, query: req.query });
  res.status(200).json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const result = await taskService.getTaskById(req.params.taskId);
  res.status(200).json(result);
});

export const create = asyncHandler(async (req, res) => {
  const result = await taskService.createTask(req.user, req.body);
  res.status(201).json(result);
});

export const update = asyncHandler(async (req, res) => {
  const result = await taskService.updateTask(req.params.taskId, req.user, req.body);
  res.status(200).json(result);
});

export const remove = asyncHandler(async (req, res) => {
  await taskService.deleteTask(req.params.taskId);
  res.status(200).json({ message: 'Task deleted successfully' });
});

export const myTasks = asyncHandler(async (req, res) => {
  const result = await taskService.getMyTasks(req.user.uid, req.query);
  res.status(200).json(result);
});

export const history = asyncHandler(async (req, res) => {
  const result = await taskService.getTaskHistory({ user: req.user, query: req.query });
  res.status(200).json(result);
});
