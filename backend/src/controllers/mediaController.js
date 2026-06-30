import { mediaService } from '../services/mediaService.js';
import { asyncHandler } from '../middleware/errorHandler.js';

export const upload = asyncHandler(async (req, res) => {
  let file = req.file;
  if (!file && req.files) {
    file = (req.files['file'] && req.files['file'][0]) || (req.files['image'] && req.files['image'][0]);
  }
  const result = await mediaService.uploadFile(file, req.user);
  res.status(201).json(result);
});

export const delete_file = asyncHandler(async (req, res) => {
  await mediaService.deleteFile(req.params.fileId);
  res.status(200).json({ message: 'File deleted successfully' });
});

export const getPublicUrl = asyncHandler(async (req, res) => {
  const result = await mediaService.getFileUrl(req.params.fileId);
  res.status(200).json({ url: result });
});

export const list = asyncHandler(async (req, res) => {
  const result = await mediaService.listFiles(req.query);
  res.status(200).json(result);
});
