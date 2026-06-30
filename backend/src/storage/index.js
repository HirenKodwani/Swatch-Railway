import { v4 as uuidv4 } from 'uuid';
import sharp from 'sharp';
import crypto from 'crypto';
import { db } from '../database/index.js';
import config from '../config/index.js';
import logger from '../logger/index.js';

export class StorageService {
  constructor(bucket) {
    this.bucket = bucket;
  }

  async uploadFile(buffer, destination, options = {}) {
    const { contentType = 'image/jpeg', isPublic = true } = options;
    const uniqueToken = uuidv4();
    const file = this.bucket.file(destination);

    await file.save(buffer, {
      metadata: {
        contentType,
        metadata: { firebaseStorageDownloadTokens: uniqueToken }
      }
    });

    const publicUrl = isPublic
      ? `https://firebasestorage.googleapis.com/v0/b/${this.bucket.name}/o/${encodeURIComponent(destination)}?alt=media&token=${uniqueToken}`
      : null;

    logger.info('StorageService', `File uploaded: ${destination}`);

    return { path: destination, url: publicUrl, token: uniqueToken };
  }

  async deleteFile(path) {
    try {
      await this.bucket.file(path).delete();
      logger.info('StorageService', `File deleted: ${path}`);
      return true;
    } catch (error) {
      logger.error('StorageService', `Failed to delete file: ${path}`, error);
      return false;
    }
  }

  async fileExists(path) {
    const [exists] = await this.bucket.file(path).exists();
    return exists;
  }

  async copyFile(sourcePath, destPath) {
    await this.bucket.file(sourcePath).copy(destPath);
    logger.info('StorageService', `File copied: ${sourcePath} -> ${destPath}`);
    return destPath;
  }

  async moveFile(sourcePath, destPath) {
    await this.copyFile(sourcePath, destPath);
    await this.deleteFile(sourcePath);
    logger.info('StorageService', `File moved: ${sourcePath} -> ${destPath}`);
    return destPath;
  }

  buildStoragePath(division, trainNumber, date, coach, taskId, evidenceType, filename) {
    const sanitize = s => String(s).replace(/[^a-zA-Z0-9_-]/g, '_');
    return [
      sanitize(division), sanitize(trainNumber), date.replace(/[/\\]/g, '-'),
      sanitize(coach), sanitize(taskId), sanitize(evidenceType), filename
    ].join('/');
  }

  computeFileHash(buffer) {
    return crypto.createHash('md5').update(buffer).digest('hex');
  }

  async findDuplicateByHash(hash) {
    const snap = await db.collection('evidence_metadata')
      .where('fileHash', '==', hash)
      .where('deleted', '==', false)
      .limit(1)
      .get();
    return snap.empty ? null : { id: snap.docs[0].id, ...snap.docs[0].data() };
  }

  async processImage(buffer, options = {}) {
    const {
      thumbnailWidth = config.imageProcessing.thumbnailWidth,
      thumbnailHeight = config.imageProcessing.thumbnailHeight,
      maxWidth = config.imageProcessing.maxWidth,
      maxHeight = config.imageProcessing.maxHeight,
      quality = config.imageProcessing.quality,
      thumbnailQuality = config.imageProcessing.thumbnailQuality
    } = options;

    const image = sharp(buffer);
    const metadata = await image.metadata();

    const webpBuffer = await image
      .resize({
        width: Math.min(metadata.width || maxWidth, maxWidth),
        height: Math.min(metadata.height || maxHeight, maxHeight),
        fit: 'inside', withoutEnlargement: true
      })
      .webp({ quality })
      .toBuffer();

    const thumbnailBuffer = await image
      .resize(thumbnailWidth, thumbnailHeight, { fit: 'cover', position: 'centre' })
      .webp({ quality: thumbnailQuality })
      .toBuffer();

    return {
      originalBuffer: buffer, webpBuffer, thumbnailBuffer,
      originalSize: buffer.length, compressedSize: webpBuffer.length, thumbnailSize: thumbnailBuffer.length,
      originalFormat: metadata.format, width: metadata.width, height: metadata.height,
      compressionRatio: ((1 - webpBuffer.length / buffer.length) * 100).toFixed(1)
    };
  }

  async uploadWithThumbnail(processed, storagePath) {
    const webpPath = `evidence/${storagePath}.webp`;
    const thumbPath = `evidence/thumbnails/${storagePath}_thumb.webp`;

    const webpResult = await this.uploadFile(processed.webpBuffer, webpPath, { contentType: 'image/webp' });
    const thumbResult = await this.uploadFile(processed.thumbnailBuffer, thumbPath, { contentType: 'image/webp' });

    return {
      webpUrl: webpResult.url, thumbUrl: thumbResult.url,
      webpPath, thumbPath,
      webpSize: processed.compressedSize, thumbSize: processed.thumbnailSize
    };
  }
}
