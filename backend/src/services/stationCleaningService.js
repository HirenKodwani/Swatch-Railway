import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { paginate } from '../utils/paginate.js';

class StationCleaningService {
  async getWorkerDashboard(workerId, query = {}) {
    const { date } = query;
    const targetDate = date || new Date().toISOString().split('T')[0];
    const workerDoc = await db.collection('users').doc(workerId).get();
    if (!workerDoc.exists) throw new NotFoundError('Worker not found');
    const worker = workerDoc.data();
    const assignments = await db.collection('areaAssignments').where('workerId', '==', workerId).where('status', '==', 'active').get();
    const areaIds = assignments.docs.map(d => d.data().areaId).filter(Boolean);
    const tasksSnapshot = await db.collection('cleaningTasks').where('workerId', '==', workerId).where('scheduledDate', '==', targetDate).get();
    const tasks = tasksSnapshot.docs.map(d => d.data());
    const total = tasks.length;
    const completed = tasks.filter(t => t.status === 'completed' || t.status === 'approved').length;
    const inProgress = tasks.filter(t => t.status === 'in_progress').length;
    const pending = tasks.filter(t => t.status === 'pending').length;
    const approved = tasks.filter(t => t.status === 'approved').length;
    const rejected = tasks.filter(t => t.status === 'rejected').length;
    const totalScore = tasks.reduce((s, t) => s + (t.score || 0), 0);
    const avgScore = total > 0 ? Math.round(totalScore / total) : 0;
    return {
      workerId, workerName: worker.fullName || '',
      date: targetDate, totalTasks: total,
      completedTasks: completed, inProgressTasks: inProgress,
      pendingTasks: pending, approvedTasks: approved,
      rejectedTasks: rejected, averageScore: avgScore,
      areas: areaIds.length, tasks
    };
  }

  async getSupervisorDashboard(supervisorId, query = {}) {
    const { date } = query;
    const targetDate = date || new Date().toISOString().split('T')[0];
    const supDoc = await db.collection('users').doc(supervisorId).get();
    if (!supDoc.exists) throw new NotFoundError('Supervisor not found');
    const supervisor = supDoc.data();
    const stationIds = supervisor.stationId ? [supervisor.stationId] : [];
    let tasks = [];
    if (stationIds.length > 0) {
      const tasksSnapshot = await db.collection('cleaningTasks').where('scheduledDate', '==', targetDate).get();
      tasks = tasksSnapshot.docs.map(d => d.data()).filter(t => stationIds.includes(t.stationId));
    }
    const total = tasks.length;
    const completed = tasks.filter(t => t.status === 'completed' || t.status === 'approved').length;
    const inProgress = tasks.filter(t => t.status === 'in_progress').length;
    const pending = tasks.filter(t => t.status === 'pending').length;
    const approved = tasks.filter(t => t.status === 'approved').length;
    const rejected = tasks.filter(t => t.status === 'rejected').length;
    const overdue = tasks.filter(t => t.status === 'pending' && t.scheduledTime < new Date().toTimeString().slice(0, 5)).length;
    const areaMap = {};
    tasks.forEach(t => {
      if (!areaMap[t.areaId]) areaMap[t.areaId] = { areaId: t.areaId, areaName: t.areaName || '', total: 0, completed: 0, score: 0 };
      areaMap[t.areaId].total++;
      if (t.status === 'completed' || t.status === 'approved') areaMap[t.areaId].completed++;
      areaMap[t.areaId].score += t.score || 0;
    });
    const areaPerformance = Object.values(areaMap).map(a => ({
      ...a, score: a.total > 0 ? Math.round(a.score / a.total) : 0
    }));
    const workerMap = {};
    tasks.forEach(t => {
      if (!t.workerId) return;
      if (!workerMap[t.workerId]) workerMap[t.workerId] = { workerId: t.workerId, workerName: t.workerName || '', total: 0, completed: 0, score: 0 };
      workerMap[t.workerId].total++;
      if (t.status === 'completed' || t.status === 'approved') workerMap[t.workerId].completed++;
      workerMap[t.workerId].score += t.score || 0;
    });
    const workerPerformance = Object.values(workerMap).map(w => ({
      ...w, score: w.total > 0 ? Math.round(w.score / w.total) : 0
    })).sort((a, b) => b.score - a.score);
    return {
      supervisorId, supervisorName: supervisor.fullName || '',
      date: targetDate, totalTasks: total,
      completedTasks: completed, inProgressTasks: inProgress,
      pendingTasks: pending, approvedTasks: approved,
      rejectedTasks: rejected, overdueTasks: overdue,
      areaPerformance, workerPerformance
    };
  }

  async generateDailyReport(stationId, query = {}) {
    const { date } = query;
    const targetDate = date || new Date().toISOString().split('T')[0];
    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');
    const station = stationDoc.data();
    const tasksSnapshot = await db.collection('cleaningTasks').where('stationId', '==', stationId).where('scheduledDate', '==', targetDate).get();
    const tasks = tasksSnapshot.docs.map(d => d.data());
    const total = tasks.length;
    const completed = tasks.filter(t => t.status === 'completed' || t.status === 'approved').length;
    const approved = tasks.filter(t => t.status === 'approved').length;
    const rejected = tasks.filter(t => t.status === 'rejected').length;
    const pending = tasks.filter(t => t.status === 'pending').length;
    const inProgress = tasks.filter(t => t.status === 'in_progress').length;
    const totalScore = tasks.reduce((s, t) => s + (t.score || 0), 0);
    const avgScore = total > 0 ? Math.round(totalScore / total) : 0;
    const areaMap = {};
    tasks.forEach(t => {
      if (!areaMap[t.areaId]) areaMap[t.areaId] = { areaName: t.areaName || '', total: 0, completed: 0, score: 0 };
      areaMap[t.areaId].total++;
      if (t.status === 'completed' || t.status === 'approved') areaMap[t.areaId].completed++;
      areaMap[t.areaId].score += t.score || 0;
    });
    const areaBreakdown = Object.entries(areaMap).map(([areaId, a]) => ({
      areaId, areaName: a.areaName, total: a.total, completed: a.completed,
      score: a.total > 0 ? Math.round(a.score / a.total) : 0
    }));
    return {
      stationId, stationName: station.stationName || '',
      date: targetDate, totalTasks: total,
      completedTasks: completed, pendingTasks: pending,
      inProgressTasks: inProgress, approvedTasks: approved,
      rejectedTasks: rejected, averageScore: avgScore,
      grade: avgScore >= 90 ? 'A' : avgScore >= 75 ? 'B' : avgScore >= 60 ? 'C' : 'D',
      areaBreakdown, generatedAt: new Date().toISOString()
    };
  }

  async generateWeeklyReport(stationId, query = {}) {
    const { endDate } = query;
    const end = endDate || new Date().toISOString().split('T')[0];
    const start = new Date(end);
    start.setDate(start.getDate() - 6);
    const startStr = start.toISOString().split('T')[0];
    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');
    const station = stationDoc.data();
    const tasksSnapshot = await db.collection('cleaningTasks').where('stationId', '==', stationId).where('scheduledDate', '>=', startStr).where('scheduledDate', '<=', end).get();
    const tasks = tasksSnapshot.docs.map(d => d.data());
    const dayMap = {};
    const days = [];
    for (let d = new Date(start); d <= new Date(end); d.setDate(d.getDate() + 1)) {
      const ds = d.toISOString().split('T')[0];
      const dayTasks = tasks.filter(t => t.scheduledDate === ds);
      dayMap[ds] = { date: ds, total: dayTasks.length, completed: dayTasks.filter(t => t.status === 'completed' || t.status === 'approved').length };
      days.push(dayMap[ds]);
    }
    const total = tasks.length;
    const completed = tasks.filter(t => t.status === 'completed' || t.status === 'approved').length;
    const totalScore = tasks.reduce((s, t) => s + (t.score || 0), 0);
    const avgScore = total > 0 ? Math.round(totalScore / total) : 0;
    const workerMap = {};
    tasks.forEach(t => {
      if (!t.workerId) return;
      if (!workerMap[t.workerId]) workerMap[t.workerId] = { workerName: t.workerName || '', total: 0, completed: 0, score: 0 };
      workerMap[t.workerId].total++;
      if (t.status === 'completed' || t.status === 'approved') workerMap[t.workerId].completed++;
      workerMap[t.workerId].score += t.score || 0;
    });
    const workerRanking = Object.entries(workerMap).map(([workerId, w]) => ({
      workerId, workerName: w.workerName, total: w.total, completed: w.completed,
      score: w.total > 0 ? Math.round(w.score / w.total) : 0
    })).sort((a, b) => b.score - a.score);
    return {
      stationId, stationName: station.stationName || '',
      startDate: startStr, endDate: end,
      totalTasks: total, completedTasks: completed,
      completionRate: total > 0 ? Math.round(completed / total * 100) : 0,
      averageScore: avgScore, grade: avgScore >= 90 ? 'A' : avgScore >= 75 ? 'B' : avgScore >= 60 ? 'C' : 'D',
      dailyBreakdown: days, workerRanking,
      generatedAt: new Date().toISOString()
    };
  }

  async generateMonthlyReport(stationId, query = {}) {
    const { month, year } = query;
    const now = new Date();
    const m = month !== undefined ? parseInt(month) : now.getMonth() + 1;
    const y = year !== undefined ? parseInt(year) : now.getFullYear();
    const startStr = `${y}-${String(m).padStart(2, '0')}-01`;
    const lastDay = new Date(y, m, 0).getDate();
    const endStr = `${y}-${String(m).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;
    const stationDoc = await db.collection('stations').doc(stationId).get();
    if (!stationDoc.exists) throw new NotFoundError('Station not found');
    const station = stationDoc.data();
    const tasksSnapshot = await db.collection('cleaningTasks').where('stationId', '==', stationId).where('scheduledDate', '>=', startStr).where('scheduledDate', '<=', endStr).get();
    const tasks = tasksSnapshot.docs.map(d => d.data());
    const total = tasks.length;
    const completed = tasks.filter(t => t.status === 'completed' || t.status === 'approved').length;
    const totalScore = tasks.reduce((s, t) => s + (t.score || 0), 0);
    const avgScore = total > 0 ? Math.round(totalScore / total) : 0;
    const areaMap = {};
    tasks.forEach(t => {
      if (!areaMap[t.areaId]) areaMap[t.areaId] = { areaName: t.areaName || '', total: 0, completed: 0, score: 0 };
      areaMap[t.areaId].total++;
      if (t.status === 'completed' || t.status === 'approved') areaMap[t.areaId].completed++;
      areaMap[t.areaId].score += t.score || 0;
    });
    const problemAreas = Object.entries(areaMap).map(([areaId, a]) => ({
      areaId, areaName: a.areaName, total: a.total, completed: a.completed,
      completionRate: a.total > 0 ? Math.round(a.completed / a.total * 100) : 0,
      score: a.total > 0 ? Math.round(a.score / a.total) : 0
    })).filter(a => a.score < 70 || a.completionRate < 70);
    const workerMap = {};
    tasks.forEach(t => {
      if (!t.workerId) return;
      if (!workerMap[t.workerId]) workerMap[t.workerId] = { workerName: t.workerName || '', total: 0, completed: 0, score: 0 };
      workerMap[t.workerId].total++;
      if (t.status === 'completed' || t.status === 'approved') workerMap[t.workerId].completed++;
      workerMap[t.workerId].score += t.score || 0;
    });
    const topWorkers = Object.entries(workerMap).map(([workerId, w]) => ({
      workerId, workerName: w.workerName, total: w.total, completed: w.completed,
      score: w.total > 0 ? Math.round(w.score / w.total) : 0
    })).sort((a, b) => b.score - a.score).slice(0, 10);
    return {
      stationId, stationName: station.stationName || '',
      month: m, year: y, period: `${startStr} to ${endStr}`,
      totalTasks: total, completedTasks: completed,
      completionRate: total > 0 ? Math.round(completed / total * 100) : 0,
      averageScore: avgScore, grade: avgScore >= 90 ? 'A' : avgScore >= 75 ? 'B' : avgScore >= 60 ? 'C' : 'D',
      topWorkers, problemAreas,
      generatedAt: new Date().toISOString()
    };
  }

  async getScoreTrend(stationId, query = {}) {
    const { months } = query;
    const numMonths = months ? parseInt(months) : 6;
    const now = new Date();
    const data = [];
    for (let i = numMonths - 1; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const m = d.getMonth() + 1;
      const y = d.getFullYear();
      const startStr = `${y}-${String(m).padStart(2, '0')}-01`;
      const lastDay = new Date(y, m, 0).getDate();
      const endStr = `${y}-${String(m).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;
      const tasksSnapshot = await db.collection('cleaningTasks').where('stationId', '==', stationId).where('scheduledDate', '>=', startStr).where('scheduledDate', '<=', endStr).get();
      const tasks = tasksSnapshot.docs.map(d => d.data());
      const withScore = tasks.filter(t => t.score);
      const avgScore = withScore.length > 0 ? Math.round(withScore.reduce((s, t) => s + (t.score || 0), 0) / withScore.length) : 0;
      data.push({ month: m, year: y, label: `${y}-${String(m).padStart(2, '0')}`, averageScore: avgScore, taskCount: tasks.length });
    }
    return { stationId, trend: data };
  }
}

export const stationCleaningService = new StationCleaningService();
