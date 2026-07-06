import { db, admin } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import logger from '../logger/index.js';

const ARCHIVE_TYPES = ['cleaning_forms', 'attendance', 'daily_activities', 'scorecards', 'complaints', 'inspections', 'execution_logs', 'billing_packs', 'passenger_feedback', 'reports', 'audit_trails', 'rejection_history'];
const RETENTION_MONTHS = 12;

class StationArchiveService {
  async triggerArchive(stationId, archiveType, month, year, user) {
    if (!stationId || !archiveType || !month || !year) {
      throw new ValidationError('stationId, archiveType, month, and year are required');
    }
    if (!ARCHIVE_TYPES.includes(archiveType)) {
      throw new ValidationError(`archiveType must be one of: ${ARCHIVE_TYPES.join(', ')}`);
    }

    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');

    const monthPad = String(month).padStart(2, '0');
    const startDate = `${year}-${monthPad}-01`;
    const endDate = `${year}-${monthPad}-31`;

    const collectionMap = {
      cleaning_forms: 'stationCleaningForms',
      attendance: 'station_attendance',
      daily_activities: 'station_daily_activities',
      scorecards: 'daily_scorecards',
      complaints: 'complaints',
      inspections: 'inspections',
      execution_logs: 'execution_logs',
      billing_packs: 'station_billing_packs',
      passenger_feedback: 'station_feedback',
      reports: 'station_reports',
      audit_trails: 'audit_logs',
      rejection_history: 'station_daily_activities',
    };

    const collectionName = collectionMap[archiveType];
    let sourceQuery = db.collection(collectionName);

    if (archiveType === 'cleaning_forms') {
      sourceQuery = sourceQuery.where('stationId', '==', stationId).where('createdAt', '>=', startDate).where('createdAt', '<=', endDate + 'T23:59:59');
    } else if (archiveType === 'attendance') {
      sourceQuery = sourceQuery.where('stationId', '==', stationId).where('date', '>=', startDate).where('date', '<=', endDate);
    } else if (archiveType === 'daily_activities') {
      sourceQuery = sourceQuery.where('stationId', '==', stationId).where('date', '>=', startDate).where('date', '<=', endDate);
    } else if (archiveType === 'scorecards') {
      sourceQuery = sourceQuery.where('stationId', '==', stationId).where('date', '>=', startDate).where('date', '<=', endDate);
    } else if (archiveType === 'complaints') {
      sourceQuery = sourceQuery.where('stationId', '==', stationId).where('createdAt', '>=', startDate).where('createdAt', '<=', endDate + 'T23:59:59');
    } else if (archiveType === 'inspections') {
      sourceQuery = sourceQuery.where('stationId', '==', stationId).where('createdAt', '>=', startDate).where('createdAt', '<=', endDate + 'T23:59:59');
    } else if (archiveType === 'execution_logs') {
      sourceQuery = sourceQuery.where('stationId', '==', stationId).where('createdAt', '>=', startDate).where('createdAt', '<=', endDate + 'T23:59:59');
    } else if (archiveType === 'billing_packs') {
      sourceQuery = sourceQuery.where('stationId', '==', stationId).where('createdAt', '>=', startDate).where('createdAt', '<=', endDate + 'T23:59:59');
    } else if (archiveType === 'passenger_feedback') {
      sourceQuery = sourceQuery.where('stationId', '==', stationId).where('createdAt', '>=', startDate).where('createdAt', '<=', endDate + 'T23:59:59');
    } else if (archiveType === 'reports') {
      sourceQuery = sourceQuery.where('stationId', '==', stationId).where('createdAt', '>=', startDate).where('createdAt', '<=', endDate + 'T23:59:59');
    } else if (archiveType === 'audit_trails') {
      sourceQuery = sourceQuery.where('action', 'in', ['UPDATE', 'DELETE', 'CREATE', 'DATA_MODIFICATION']).where('timestamp', '>=', startDate).where('timestamp', '<=', endDate + 'T23:59:59');
    } else if (archiveType === 'rejection_history') {
      sourceQuery = sourceQuery.where('stationId', '==', stationId).where('status', '==', 'REJECTED').where('date', '>=', startDate).where('date', '<=', endDate);
    }

    const snapshot = await sourceQuery.limit(500).get();
    if (snapshot.empty) {
      return { message: `No ${archiveType} records found for ${month}/${year}`, archived: 0 };
    }

    const records = [];
    snapshot.forEach(doc => records.push({ id: doc.id, ...doc.data() }));

    const ref = db.collection('station_archives').doc();
    const now = new Date().toISOString();
    const archive = {
      uid: ref.id,
      stationId,
      stationName: stationDoc.data().stationName || '',
      archiveType,
      month: parseInt(month),
      year: parseInt(year),
      recordCount: records.length,
      data: records,
      status: 'archived',
      archivedBy: user.uid,
      archivedByName: user.fullName || '',
      archivedAt: now,
      createdAt: now,
    };
    await ref.set(archive);

    logger.info('StationArchive', `Archived ${records.length} ${archiveType} records for ${stationId} ${month}/${year}`);
    return { message: `${records.length} ${archiveType} records archived`, uid: ref.id, recordCount: records.length };
  }

  async listArchives(query = {}) {
    const { stationId, archiveType, month, year, contractor, area, user, status, startDate, endDate, limit = 50 } = query;
    let q = db.collection('station_archives').orderBy('archivedAt', 'desc');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (archiveType) q = q.where('archiveType', '==', archiveType);
    if (month) q = q.where('month', '==', parseInt(month));
    if (year) q = q.where('year', '==', parseInt(year));
    if (status) q = q.where('status', '==', status);
    const snapshot = await q.limit(parseInt(limit)).get();
    let archives = [];
    snapshot.forEach(doc => {
      const d = doc.data();
      archives.push({
        uid: d.uid, stationId: d.stationId, stationName: d.stationName,
        archiveType: d.archiveType, month: d.month, year: d.year,
        recordCount: d.recordCount, status: d.status,
        archivedBy: d.archivedBy, archivedAt: d.archivedAt,
      });
    });
    if (contractor) archives = archives.filter(a => a.stationName?.toLowerCase().includes(contractor.toLowerCase()));
    if (area) archives = archives.filter(a => a.archiveType?.toLowerCase().includes(area.toLowerCase()));
    if (user) archives = archives.filter(a => a.archivedBy?.toLowerCase().includes(user.toLowerCase()));
    if (startDate) archives = archives.filter(a => a.archivedAt >= startDate);
    if (endDate) archives = archives.filter(a => a.archivedAt <= endDate + 'T23:59:59');
    return { count: archives.length, archives };
  }

  async getArchiveById(uid) {
    const doc = await db.collection('station_archives').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Archive not found');
    return { id: doc.id, ...doc.data() };
  }

  async purgeArchives(stationId, archiveType, olderThanMonths = RETENTION_MONTHS) {
    let q = db.collection('station_archives');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (archiveType) q = q.where('archiveType', '==', archiveType);

    const cutoffDate = new Date();
    cutoffDate.setMonth(cutoffDate.getMonth() - olderThanMonths);
    const cutoffStr = cutoffDate.toISOString();

    const snapshot = await q.get();
    const batch = db.batch();
    let count = 0;

    snapshot.forEach(doc => {
      const d = doc.data();
      if (d.archivedAt && d.archivedAt < cutoffStr) {
        batch.delete(doc.ref);
        count++;
      }
    });

    if (count > 0) await batch.commit();
    logger.info('StationArchive', `Purged ${count} archives older than ${olderThanMonths} months`);
    return { message: `${count} archives purged`, purged: count };
  }
}

export const stationArchiveService = new StationArchiveService();
