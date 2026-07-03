import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

class ScorecardService {
  async createDailyScorecard(userData, body) {
    const { stationId, date, areaWiseScores, overallStationScore, inspectorName } = body;
    if (!stationId || !date || overallStationScore === undefined) throw new ValidationError('stationId, date, and overallStationScore are required');

    const ref = db.collection('daily_scorecards').doc();
    const data = {
      uid: ref.id, stationId, date,
      areaWiseScores: areaWiseScores || {},
      overallStationScore,
      grade: overallStationScore >= 90 ? 'A' : overallStationScore >= 80 ? 'B' : overallStationScore >= 70 ? 'C' : 'D',
      inspectorName: inspectorName || userData.fullName || '',
      inspectorDesignation: body.inspectorDesignation || '',
      remarks: body.remarks || '',
      certified: body.certified || false,
      certifiedBy: body.certifiedBy || null,
      forwardedToCommercial: body.forwardedToCommercial || false,
      createdBy: userData.uid,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    };
    await ref.set(data);
    return { message: 'Daily scorecard created', uid: ref.id, scorecard: data };
  }

  async getDailyScorecards(query = {}) {
    const { stationId, date, startDate, endDate, limit = 50, cursor } = query;
    let q = db.collection('daily_scorecards');
    if (stationId) q = q.where('stationId', '==', stationId);
    if (date) q = q.where('date', '==', date);
    if (startDate) q = q.where('date', '>=', startDate);
    if (endDate) q = q.where('date', '<=', endDate);
    const result = await paginate(q, { limit, cursor, orderBy: 'date', orderDir: 'desc' });
    return { count: result.items.length, scorecards: result.items, pagination: result.pagination };
  }

  async getMonthlyScorecard(stationId, month, year) {
    if (!stationId || !month || !year) throw new ValidationError('stationId, month, and year are required');
    const monthPad = String(month).padStart(2, '0');
    const startDate = `${year}-${monthPad}-01`;
    const endDate = `${year}-${monthPad}-31`;

    const snapshot = await db.collection('daily_scorecards')
      .where('stationId', '==', stationId)
      .where('date', '>=', startDate)
      .where('date', '<=', endDate).get();

    const scorecards = [];
    snapshot.forEach(doc => scorecards.push(doc.data()));

    if (scorecards.length === 0) return { stationId, month, year, averageScore: 0, totalDays: 0, scorecards: [] };

    const total = scorecards.reduce((s, c) => s + (c.overallStationScore || 0), 0);
    const avg = Math.round(total / scorecards.length);
    const best = Math.max(...scorecards.map(c => c.overallStationScore || 0));
    const worst = Math.min(...scorecards.map(c => c.overallStationScore || 0));
    const grades = {};
    scorecards.forEach(c => { const g = c.grade || 'N/A'; grades[g] = (grades[g] || 0) + 1; });

    return {
      stationId, month, year,
      totalDays: scorecards.length,
      averageScore: avg,
      bestScore: best,
      worstScore: worst,
      gradeDistribution: grades,
      certified: scorecards.every(c => c.certified),
      scorecards
    };
  }

  async getScorecardById(uid) {
    const doc = await db.collection('daily_scorecards').doc(uid).get();
    if (!doc.exists) throw new NotFoundError('Scorecard not found');
    return { id: doc.id, ...doc.data() };
  }

  async updateScorecard(uid, body) {
    const ref = db.collection('daily_scorecards').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Scorecard not found');
    const allowed = ['areaWiseScores', 'overallStationScore', 'inspectorName', 'inspectorDesignation', 'remarks', 'certified', 'certifiedBy', 'forwardedToCommercial'];
    const updates = {};
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }
    if (body.overallStationScore !== undefined) {
      updates.grade = body.overallStationScore >= 90 ? 'A' : body.overallStationScore >= 80 ? 'B' : body.overallStationScore >= 70 ? 'C' : 'D';
    }
    updates.updatedAt = new Date().toISOString();
    await ref.update(updates);
    return { message: 'Scorecard updated', uid };
  }

  async deleteScorecard(uid) {
    const ref = db.collection('daily_scorecards').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundError('Scorecard not found');
    await ref.delete();
    return { message: 'Scorecard deleted' };
  }
}

export const scorecardService = new ScorecardService();
