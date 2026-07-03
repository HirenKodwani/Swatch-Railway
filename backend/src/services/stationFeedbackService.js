import jwt from 'jsonwebtoken';
import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import config from '../config/index.js';
import { paginate } from '../utils/paginate.js';
import otpStore from '../utils/otpStore.js';

const FEEDBACK_CATEGORIES = [
  'toilet_cleanliness', 'platform_cleanliness', 'waiting_room_cleanliness',
  'garbage_dustbin', 'smell_odour', 'water_booth_cleanliness',
  'staff_behaviour', 'other'
];

class StationFeedbackService {
  async sendOtp(body) {
    const { phone, stationId } = body;
    if (!phone) throw new ValidationError('Phone number is required');

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const key = `station_fb_${phone}`;
    await otpStore.set(key, otp);

    if (stationId) {
      await otpStore.set(`station_fb_ctx_${phone}`, stationId);
    }

    const TWO_FACTOR_API_KEY = config.sms.twoFactorApiKey;
    if (!TWO_FACTOR_API_KEY) {
      throw new Error('2Factor API key not configured');
    }

    const url = `https://2factor.in/API/V1/${TWO_FACTOR_API_KEY}/SMS/91${phone}/${otp}`;
    const axios = (await import('axios')).default;
    const response = await axios.get(url);

    if (response.data.Status === "Success") {
      return { success: true, message: "OTP sent to your mobile number." };
    }
    throw new Error(response.data.Details || "Failed to send SMS");
  }

  async verifyOtp(body) {
    const { phone, otp } = body;
    if (!phone || !otp) {
      throw new ValidationError("Phone number and OTP are required.");
    }

    const key = `station_fb_${phone}`;
    const storedOtp = await otpStore.get(key);
    if (!storedOtp) {
      throw new ValidationError("OTP expired or not requested. Please try again.");
    }

    const attemptKey = `ATTEMPT_${key}`;
    const attempts = (await otpStore.get(attemptKey)) || 0;
    if (attempts >= 5) {
      throw new ValidationError("Too many attempts. Please request a new OTP.");
    }

    if (storedOtp !== otp) {
      await otpStore.set(attemptKey, attempts + 1);
      throw new ValidationError("Invalid OTP. Please check and try again.");
    }

    await Promise.all([
      otpStore.delete(key),
      otpStore.delete(attemptKey)
    ]);

    const token = jwt.sign({ phone, purpose: 'station_feedback' }, config.jwtSecret, { expiresIn: '1h' });
    return { success: true, message: "Verified successfully.", token };
  }

  async submitFeedback(body) {
    const { stationId, areaId, category, rating, comments, phone, imageUrl } = body;

    if (!stationId || !category || rating === undefined) {
      throw new ValidationError('stationId, category, and rating are required');
    }
    if (!FEEDBACK_CATEGORIES.includes(category)) {
      throw new ValidationError(`Invalid category. Must be one of: ${FEEDBACK_CATEGORIES.join(', ')}`);
    }

    const ratingNum = Number(rating);
    if (isNaN(ratingNum) || ratingNum < 1 || ratingNum > 5) {
      throw new ValidationError('Rating must be between 1 and 5');
    }

    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');

    let areaName = '';
    if (areaId) {
      const areaDoc = await db.collection('areas').doc(areaId).get();
      if (areaDoc.exists) areaName = areaDoc.data().areaName || '';
    }

    const ref = db.collection('station_feedback').doc();
    const data = {
      uid: ref.id,
      stationId,
      stationName: stationDoc.data().stationName || '',
      areaId: areaId || null,
      areaName,
      category,
      rating: ratingNum,
      comments: comments || '',
      phone: phone || '',
      imageUrl: imageUrl || '',
      isNegative: ratingNum <= 2,
      createdAt: new Date().toISOString()
    };
    await ref.set(data);

    return { message: 'Feedback submitted successfully', uid: ref.id, feedback: data };
  }

  async listFeedback(query = {}) {
    const { stationId, category, isNegative, rating, startDate, endDate, limit = 50, cursor } = query;
    let firestoreQuery = db.collection('station_feedback');
    if (stationId) firestoreQuery = firestoreQuery.where('stationId', '==', stationId);
    if (category) firestoreQuery = firestoreQuery.where('category', '==', category);
    if (isNegative !== undefined) firestoreQuery = firestoreQuery.where('isNegative', '==', isNegative === 'true');
    if (rating) firestoreQuery = firestoreQuery.where('rating', '==', Number(rating));

    const result = await paginate(firestoreQuery, { limit, cursor, orderBy: 'createdAt', orderDir: 'desc' });

    let items = result.items;
    if (startDate || endDate) {
      items = items.filter(item => {
        const d = new Date(item.createdAt);
        if (startDate && d < new Date(startDate)) return false;
        if (endDate && d > new Date(endDate + 'T23:59:59Z')) return false;
        return true;
      });
    }

    return { count: items.length, feedbacks: items, pagination: result.pagination };
  }

  async getFeedbackSummary(stationId, query = {}) {
    if (!stationId) throw new ValidationError('stationId is required');
    const { startDate, endDate } = query;

    let firestoreQuery = db.collection('station_feedback').where('stationId', '==', stationId);
    const snapshot = await firestoreQuery.get();

    const total = [];
    snapshot.forEach(doc => total.push(doc.data()));

    let filtered = total;
    if (startDate || endDate) {
      filtered = filtered.filter(item => {
        const d = new Date(item.createdAt);
        if (startDate && d < new Date(startDate)) return false;
        if (endDate && d > new Date(endDate + 'T23:59:59Z')) return false;
        return true;
      });
    }

    const categoryBreakdown = {};
    let totalRating = 0;
    let negativeCount = 0;

    for (const fb of filtered) {
      totalRating += fb.rating || 0;
      if (fb.isNegative) negativeCount++;
      const cat = fb.category || 'other';
      if (!categoryBreakdown[cat]) {
        categoryBreakdown[cat] = { count: 0, totalRating: 0 };
      }
      categoryBreakdown[cat].count++;
      categoryBreakdown[cat].totalRating += fb.rating || 0;
    }

    for (const cat of Object.keys(categoryBreakdown)) {
      categoryBreakdown[cat].averageRating = categoryBreakdown[cat].count > 0
        ? Math.round((categoryBreakdown[cat].totalRating / categoryBreakdown[cat].count) * 10) / 10
        : 0;
    }

    return {
      stationId,
      totalFeedback: filtered.length,
      averageRating: filtered.length > 0 ? Math.round((totalRating / filtered.length) * 10) / 10 : 0,
      negativeCount,
      positiveCount: filtered.length - negativeCount,
      categoryBreakdown
    };
  }

  async getStationQr(stationId) {
    if (!stationId) throw new ValidationError('stationId is required');
    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');
    const stationData = stationDoc.data();

    const feedbackUrl = `${process.env.APP_BASE_URL || 'https://swachhrailways.com'}/station-feedback?stationId=${stationId}`;

    return {
      stationId,
      stationName: stationData.stationName,
      stationCode: stationData.stationCode,
      feedbackUrl
    };
  }
}

export const stationFeedbackService = new StationFeedbackService();
