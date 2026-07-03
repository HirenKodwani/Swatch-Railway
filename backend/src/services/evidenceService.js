import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError, ForbiddenError } from '../errors/index.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import logger from '../logger/index.js';
import config from '../config/index.js';
import { v4 as uuidv4 } from 'uuid';
import sharp from 'sharp';
import crypto from 'crypto';

const EVIDENCE_TYPES = [
  'Before', 'After', 'Exception', 'Complaint', 'Resolution',
  'Attendance', 'FaceVerification', 'GPSVerification',
  'SupervisorVerification', 'LinenEvidence', 'PassengerComplaintEvidence'
];

const STORAGE_TIER = {
  ACTIVE: 'active',
  ARCHIVE: 'archive',
  LONG_TERM: 'long_term'
};

class EvidenceService {
  async getEvidenceTypes() {
    return EVIDENCE_TYPES;
  }

  async logAudit(action, params) {
    const {
      evidenceId, userId, userName, userRole, trainNumber, coach,
      taskId, complaintId, details
    } = params;
    await db.collection('audit_evidence').add({
      action,
      evidenceId: evidenceId || null,
      userId: userId || null,
      userName: userName || 'System',
      userRole: userRole || null,
      trainNumber: trainNumber || null,
      coach: coach || null,
      taskId: taskId || null,
      complaintId: complaintId || null,
      details: details || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  buildStoragePath(division, trainNumber, date, coach, taskId, evidenceType, filename) {
    const sanitize = s => String(s).replace(/[^a-zA-Z0-9_-]/g, '_');
    return [
      sanitize(division),
      sanitize(trainNumber),
      date.replace(/[/\\]/g, '-'),
      sanitize(coach),
      sanitize(taskId),
      sanitize(evidenceType),
      filename
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
      thumbnailWidth = config.imageProcessing.thumbnailWidth || 200,
      thumbnailHeight = config.imageProcessing.thumbnailHeight || 200,
      maxWidth = config.imageProcessing.maxWidth || 1920,
      maxHeight = config.imageProcessing.maxHeight || 1080,
      quality = config.imageProcessing.quality || 80,
      thumbnailQuality = config.imageProcessing.thumbnailQuality || 60
    } = options;

    const image = sharp(buffer);
    const metadata = await image.metadata();

    const webpBuffer = await image
      .resize({
        width: Math.min(metadata.width || maxWidth, maxWidth),
        height: Math.min(metadata.height || maxHeight, maxHeight),
        fit: 'inside',
        withoutEnlargement: true
      })
      .webp({ quality })
      .toBuffer();

    const thumbnailBuffer = await image
      .resize(thumbnailWidth, thumbnailHeight, { fit: 'cover', position: 'centre' })
      .webp({ quality: thumbnailQuality })
      .toBuffer();

    return {
      originalBuffer: buffer,
      webpBuffer,
      thumbnailBuffer,
      originalSize: buffer.length,
      compressedSize: webpBuffer.length,
      thumbnailSize: thumbnailBuffer.length,
      originalFormat: metadata.format,
      width: metadata.width,
      height: metadata.height,
      compressionRatio: ((1 - webpBuffer.length / buffer.length) * 100).toFixed(1)
    };
  }

  async uploadToStorage(storagePath, processed) {
    const bucket = db.getBucket();
    const uniqueToken = crypto.randomUUID();
    const webpPath = `evidence/${storagePath}.webp`;
    const webpFile = bucket.file(webpPath);
    await webpFile.save(processed.webpBuffer, {
      metadata: {
        contentType: 'image/webp',
        metadata: { firebaseStorageDownloadTokens: uniqueToken }
      }
    });

    const thumbPath = `evidence/thumbnails/${storagePath}_thumb.webp`;
    const thumbFile = bucket.file(thumbPath);
    await thumbFile.save(processed.thumbnailBuffer, {
      metadata: {
        contentType: 'image/webp',
        metadata: { firebaseStorageDownloadTokens: crypto.randomUUID() }
      }
    });

    const bucketName = bucket.name;
    const baseUrl = `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/`;

    return {
      webpUrl: `${baseUrl}${encodeURIComponent(webpPath)}?alt=media&token=${uniqueToken}`,
      thumbUrl: `${baseUrl}${encodeURIComponent(thumbPath)}?alt=media`,
      webpPath,
      thumbPath,
      webpSize: processed.compressedSize,
      thumbSize: processed.thumbnailSize
    };
  }

  buildEvidenceMetadata(params) {
    const {
      storageRef, trainNumber, coach, taskId, taskType,
      evidenceType, uploadedBy, uploadedByName, uploadedByRole,
      division, contractor, runInstanceId, fileHash,
      originalSize, compressedSize, thumbnailSize,
      compressionRatio, width, height, originalFormat,
      webpUrl, thumbUrl, webpPath, thumbPath,
      gpsLat, gpsLng, remarks, complaintId, attendanceId
    } = params;

    return {
      fileHash,
      storageRef,
      trainNumber: trainNumber || null,
      coach: coach || null,
      taskId: taskId || null,
      taskType: taskType || null,
      evidenceType: evidenceType || 'Before',
      uploadedBy,
      uploadedByName: uploadedByName || 'Unknown',
      uploadedByRole: uploadedByRole || null,
      division: division || null,
      contractor: contractor || null,
      runInstanceId: runInstanceId || null,
      complaintId: complaintId || null,
      attendanceId: attendanceId || null,
      gpsLat: gpsLat || null,
      gpsLng: gpsLng || null,
      remarks: remarks || null,
      webpUrl,
      thumbUrl,
      webpPath,
      thumbPath,
      originalFormat: originalFormat || 'unknown',
      originalSize,
      compressedSize,
      thumbnailSize,
      compressionRatio: parseFloat(compressionRatio) || 0,
      width: width || null,
      height: height || null,
      storageTier: STORAGE_TIER.ACTIVE,
      uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
      archivedAt: null,
      longTermAt: null,
      lastAccessedAt: admin.firestore.FieldValue.serverTimestamp(),
      deleted: false,
      deletedAt: null,
      viewCount: 0,
      downloadCount: 0,
      contentType: 'image/webp'
    };
  }

  async uploadEvidence(file, body, user) {
    if (!file) throw new ValidationError('No file uploaded');

    const {
      trainNumber, coach, taskId, taskType, evidenceType,
      contractor, runInstanceId, complaintId, attendanceId,
      gpsLat, gpsLng, remarks
    } = body;

    const division = user.division || 'Unknown';
    const date = new Date().toISOString().split('T')[0];

    const fileHash = this.computeFileHash(file.buffer);
    const existing = await this.findDuplicateByHash(fileHash);
    if (existing) {
      return {
        success: true,
        duplicate: true,
        evidenceId: existing.id,
        message: 'Duplicate image detected. Returning existing record.',
        ...existing
      };
    }

    const processed = await this.processImage(file.buffer);

    const filename = `${uuidv4()}_${Date.now()}`;
    const storageRef = this.buildStoragePath(
      division, trainNumber || 'UNKNOWN', date,
      coach || 'GENERAL', taskId || 'no-task', evidenceType || 'Before', filename
    );

    const storageResult = await this.uploadToStorage(storageRef, processed);

    const meta = this.buildEvidenceMetadata({
      storageRef,
      trainNumber,
      coach,
      taskId,
      taskType,
      evidenceType: evidenceType || 'Before',
      uploadedBy: user.uid,
      uploadedByName: user.fullName || user.name,
      uploadedByRole: user.role,
      division,
      contractor,
      runInstanceId,
      fileHash,
      complaintId,
      attendanceId,
      gpsLat,
      gpsLng,
      remarks,
      originalSize: processed.originalSize,
      compressedSize: processed.compressedSize,
      thumbnailSize: processed.thumbnailSize,
      compressionRatio: processed.compressionRatio,
      width: processed.width,
      height: processed.height,
      originalFormat: processed.originalFormat,
      webpUrl: storageResult.webpUrl,
      thumbUrl: storageResult.thumbUrl,
      webpPath: storageResult.webpPath,
      thumbPath: storageResult.thumbPath
    });

    const docRef = await db.collection('evidence_metadata').add(meta);

    await this.logAudit('EVIDENCE_UPLOADED', {
      evidenceId: docRef.id, userId: user.uid, userName: user.fullName,
      userRole: user.role, trainNumber, coach, taskId, complaintId,
      details: `Uploaded ${evidenceType || 'Before'} evidence (${processed.compressionRatio}% compression)`
    });

    return {
      success: true,
      evidenceId: docRef.id,
      webpUrl: storageResult.webpUrl,
      thumbUrl: storageResult.thumbUrl,
      originalSize: processed.originalSize,
      compressedSize: processed.compressedSize,
      compressionRatio: processed.compressionRatio,
      width: processed.width,
      height: processed.height,
      message: 'Evidence uploaded and compressed successfully'
    };
  }

  async uploadEvidenceBase64(base64Data, body, user) {
    if (!base64Data) throw new ValidationError('No image data provided');
    const raw = base64Data.replace(/^data:image\/\w+;base64,/, '');
    const buffer = Buffer.from(raw, 'base64');
    const file = { buffer, mimetype: 'image/png', originalname: `evidence_${Date.now()}.png` };
    return this.uploadEvidence(file, body, user);
  }

  async getEvidenceById(id) {
    const collections = ['evidence_metadata', 'archive_evidence', 'long_term_evidence'];
    for (const coll of collections) {
      const doc = await db.collection(coll).doc(id).get();
      if (doc.exists) {
        const data = doc.data();
        doc.ref.update({
          viewCount: admin.firestore.FieldValue.increment(1),
          lastAccessedAt: admin.firestore.FieldValue.serverTimestamp()
        }).catch(() => {});
        return { id: doc.id, ...data };
      }
    }
    return null;
  }

  async updateEvidence(id, body) {
    const allowed = ['remarks', 'gpsLat', 'gpsLng', 'evidenceType'];
    const updates = {};
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }
    updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    const doc = await db.collection('evidence_metadata').doc(id).get();
    if (!doc.exists) throw new NotFoundError('Evidence not found');

    await doc.ref.update(updates);
    return { success: true, message: 'Evidence updated' };
  }

  async deleteEvidence(id) {
    const doc = await db.collection('evidence_metadata').doc(id).get();
    if (!doc.exists) throw new NotFoundError('Evidence not found');

    await doc.ref.update({
      deleted: true,
      deletedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await this.logAudit('EVIDENCE_DELETED', {
      evidenceId: id, details: 'Evidence soft-deleted'
    });

    return { success: true, message: 'Evidence deleted' };
  }

  async searchEvidence(params) {
    const {
      trainNumber, coach, dateFrom, dateTo, contractor, worker,
      supervisor, taskType, evidenceType, complaintId, runInstanceId,
      storageTier, uploadedBy, limit = 50, offset = 0
    } = params;

    const collections = storageTier
      ? [storageTier === STORAGE_TIER.ACTIVE ? 'evidence_metadata' :
         storageTier === STORAGE_TIER.ARCHIVE ? 'archive_evidence' : 'long_term_evidence']
      : ['evidence_metadata', 'archive_evidence', 'long_term_evidence'];

    const results = [];
    let totalCount = 0;

    for (const coll of collections) {
      let query = db.collection(coll);
      const constraints = [];

      if (trainNumber) constraints.push({ field: 'trainNumber', op: '==', val: trainNumber });
      if (coach) constraints.push({ field: 'coach', op: '==', val: coach });
      if (contractor) constraints.push({ field: 'contractor', op: '==', val: contractor });
      if (uploadedBy) constraints.push({ field: 'uploadedBy', op: '==', val: uploadedBy });
      if (evidenceType) constraints.push({ field: 'evidenceType', op: '==', val: evidenceType });
      if (taskType) constraints.push({ field: 'taskType', op: '==', val: taskType });
      if (complaintId) constraints.push({ field: 'complaintId', op: '==', val: complaintId });
      if (runInstanceId) constraints.push({ field: 'runInstanceId', op: '==', val: runInstanceId });
      constraints.push({ field: 'deleted', op: '==', val: false });

      let snap;
      try {
        if (constraints.length > 0) {
          const first = constraints[0];
          query = query.where(first.field, first.op, first.val);
        }
        snap = await query.orderBy('uploadedAt', 'desc').limit(200).get();
      } catch {
        snap = await query.limit(200).get();
      }

      let docs = snap.docs.map(d => ({ id: d.id, ...d.data() }));

      for (let i = 1; i < constraints.length; i++) {
        const c = constraints[i];
        docs = docs.filter(d => d[c.field] === c.val);
      }

      if (worker) docs = docs.filter(d => d.uploadedByName?.toLowerCase().includes(worker.toLowerCase()));
      if (supervisor) docs = docs.filter(d => d.uploadedByName?.toLowerCase().includes(supervisor.toLowerCase()) || d.uploadedByRole?.toLowerCase() === 'supervisor');
      if (dateFrom) docs = docs.filter(d => d.uploadedAt?.toDate() >= new Date(dateFrom));
      if (dateTo) docs = docs.filter(d => d.uploadedAt?.toDate() <= new Date(dateTo + 'T23:59:59Z'));

      totalCount += docs.length;
      results.push(...docs);
    }

    results.sort((a, b) => {
      const tA = a.uploadedAt?.toDate?.() || new Date(0);
      const tB = b.uploadedAt?.toDate?.() || new Date(0);
      return tB - tA;
    });

    return {
      total: results.length,
      page: Math.floor(offset / limit) + 1,
      limit,
      results: results.slice(offset, offset + limit)
    };
  }

  async archiveEvidence(id) {
    const doc = await db.collection('evidence_metadata').doc(id).get();
    if (!doc.exists) throw new NotFoundError('Evidence not found in active storage');

    const data = doc.data();
    await db.collection('archive_evidence').doc(id).set({
      ...data, storageTier: STORAGE_TIER.ARCHIVE,
      archivedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    await doc.ref.update({
      storageTier: STORAGE_TIER.ARCHIVE,
      archivedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await this.logAudit('EVIDENCE_ARCHIVED_MANUAL', {
      evidenceId: id, details: 'Manually archived'
    });

    return { success: true, message: 'Evidence archived' };
  }

  async restoreEvidence(id) {
    const archiveDoc = await db.collection('archive_evidence').doc(id).get();
    if (!archiveDoc.exists) {
      const longDoc = await db.collection('long_term_evidence').doc(id).get();
      if (!longDoc.exists) throw new NotFoundError('Evidence not found in archive or long-term storage');
      const data = longDoc.data();
      await db.collection('evidence_metadata').doc(id).set({
        ...data,
        storageTier: STORAGE_TIER.ACTIVE,
        archivedAt: null,
        longTermAt: null,
        lastAccessedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      await this.logAudit('EVIDENCE_RESTORED', {
        evidenceId: id, details: 'Restored from long-term to active'
      });
      return { success: true, restored: true, tier: 'long_term' };
    }

    const data = archiveDoc.data();
    await db.collection('evidence_metadata').doc(id).set({
      ...data,
      storageTier: STORAGE_TIER.ACTIVE,
      archivedAt: null,
      lastAccessedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    await this.logAudit('EVIDENCE_RESTORED', {
      evidenceId: id, details: 'Restored from archive to active'
    });
    return { success: true, restored: true, tier: 'archive' };
  }

  async getStorageAnalytics() {
    const collections = ['evidence_metadata', 'archive_evidence', 'long_term_evidence'];
    const tierNames = ['Active', 'Archive', 'Long Term'];
    const result = [];

    for (let i = 0; i < collections.length; i++) {
      const snap = await db.collection(collections[i])
        .where('deleted', '==', false)
        .limit(200).get();

      let totalSize = 0;
      let totalThumbSize = 0;
      let count = 0;
      const trainMap = {};
      const contractorMap = {};
      const dateCounts = {};

      snap.docs.forEach(doc => {
        const d = doc.data();
        count++;
        totalSize += d.compressedSize || d.originalSize || 0;
        totalThumbSize += d.thumbnailSize || 0;
        if (d.trainNumber) trainMap[d.trainNumber] = (trainMap[d.trainNumber] || 0) + 1;
        if (d.contractor) contractorMap[d.contractor] = (contractorMap[d.contractor] || 0) + 1;
        if (d.uploadedAt?.toDate) {
          const dStr = d.uploadedAt.toDate().toISOString().split('T')[0];
          dateCounts[dStr] = (dateCounts[dStr] || 0) + 1;
        }
      });

      result.push({
        tier: tierNames[i],
        collection: collections[i],
        totalDocuments: count,
        totalStorageBytes: totalSize,
        totalThumbnailBytes: totalThumbSize,
        totalBytes: totalSize + totalThumbSize,
        totalMB: ((totalSize + totalThumbSize) / (1024 * 1024)).toFixed(2),
        uniqueTrains: Object.keys(trainMap).length,
        uniqueContractors: Object.keys(contractorMap).length,
        dailyCounts: dateCounts
      });
    }

    const totalBytes = result.reduce((s, r) => s + (r.totalBytes || 0), 0);

    const forecast = await this.forecastStorageGrowth();

    return {
      tiers: result,
      totals: {
        totalDocuments: result.reduce((s, r) => s + r.totalDocuments, 0),
        totalMB: (totalBytes / (1024 * 1024)).toFixed(2),
        totalGB: (totalBytes / (1024 * 1024 * 1024)).toFixed(4)
      },
      forecast
    };
  }

  async forecastStorageGrowth() {
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const snap = await db.collection('evidence_metadata')
      .where('uploadedAt', '>=', thirtyDaysAgo)
      .where('deleted', '==', false)
      .limit(200).get();

    const dailyBytes = {};
    snap.docs.forEach(doc => {
      const d = doc.data();
      if (d.uploadedAt?.toDate) {
        const dStr = d.uploadedAt.toDate().toISOString().split('T')[0];
        dailyBytes[dStr] = (dailyBytes[dStr] || 0) + (d.compressedSize || d.originalSize || 0);
      }
    });

    const days = Object.keys(dailyBytes).sort();
    if (days.length < 2) {
      return { avgDailyMB: 0, projected30DayMB: 0, projected90DayMB: 0, note: 'Insufficient data for forecast' };
    }

    const totalBytesInPeriod = Object.values(dailyBytes).reduce((s, v) => s + v, 0);
    const avgDailyBytes = totalBytesInPeriod / days.length;

    return {
      avgDailyMB: (avgDailyBytes / (1024 * 1024)).toFixed(2),
      projected30DayMB: ((avgDailyBytes * 30) / (1024 * 1024)).toFixed(2),
      projected90DayMB: ((avgDailyBytes * 90) / (1024 * 1024)).toFixed(2),
      basedOnDays: days.length
    };
  }

  async getPerTrainStorage() {
    const snap = await db.collection('evidence_metadata')
      .where('deleted', '==', false)
      .limit(200).get();
    const trainCounts = {};
    snap.docs.forEach(doc => {
      const t = doc.data().trainNumber || 'UNKNOWN';
      trainCounts[t] = (trainCounts[t] || 0) + 1;
    });
    const sorted = Object.entries(trainCounts)
      .map(([train, count]) => ({ train, count }))
      .sort((a, b) => b.count - a.count);
    return { success: true, trains: sorted };
  }

  async getPerContractorStorage() {
    const snap = await db.collection('evidence_metadata')
      .where('deleted', '==', false)
      .limit(200).get();
    const contractorStats = {};
    snap.docs.forEach(doc => {
      const d = doc.data();
      const c = d.contractor || 'Unknown';
      if (!contractorStats[c]) contractorStats[c] = { count: 0, totalBytes: 0 };
      contractorStats[c].count++;
      contractorStats[c].totalBytes += d.compressedSize || d.originalSize || 0;
    });
    return { success: true, contractors: contractorStats };
  }

  async getDailyUploadCount(days = 30) {
    const from = new Date(Date.now() - days * 86400000).toISOString().split('T')[0];
    const snap = await db.collection('evidence_metadata')
      .where('deleted', '==', false)
      .limit(200).get();
    const dailyCounts = {};
    snap.docs.forEach(doc => {
      const d = doc.data();
      if (d.uploadedAt?.toDate) {
        const day = d.uploadedAt.toDate().toISOString().split('T')[0];
        if (day >= from) dailyCounts[day] = (dailyCounts[day] || 0) + 1;
      }
    });
    return { success: true, from, daily: dailyCounts };
  }

  async performBackup(type = 'daily') {
    const collections = ['evidence_metadata', 'archive_evidence', 'long_term_evidence'];
    const backup = { timestamp: new Date().toISOString(), type, collections: {} };

    for (const coll of collections) {
      const snap = await db.collection(coll).limit(200).get();
      backup.collections[coll] = snap.docs.map(d => ({ id: d.id, data: d.data() }));
    }

    const backupRef = db.collection('backup_logs').doc();
    await backupRef.set({
      backupId: backupRef.id,
      type,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      recordCounts: Object.fromEntries(
        Object.entries(backup.collections).map(([k, v]) => [k, v.length])
      ),
      status: 'completed'
    });

    return {
      backupId: backupRef.id,
      type,
      timestamp: backup.timestamp,
      recordCounts: Object.fromEntries(
        Object.entries(backup.collections).map(([k, v]) => [k, v.length])
      ),
      status: 'completed'
    };
  }

  async getBackupLogs(limit = 20) {
    const snap = await db.collection('backup_logs')
      .orderBy('timestamp', 'desc')
      .limit(parseInt(limit))
      .get();
    const logs = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    return { success: true, count: logs.length, logs };
  }
}

export const evidenceService = new EvidenceService();
