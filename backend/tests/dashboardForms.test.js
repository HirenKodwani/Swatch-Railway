import { describe, it, expect, vi } from 'vitest';

const makeDocs = (arr) => ({
  docs: arr.map((data, i) => ({ id: `doc_${i}`, data: () => data })),
  forEach(cb) { this.docs.forEach(cb); },
  size: arr.length,
  empty: arr.length === 0,
});

const collections = {
  users: makeDocs([
    { userType: 'railway', status: 'APPROVED', zone: 'Z1', division: 'D1' },
    { userType: 'contractor', status: 'PENDING', zone: 'Z1', division: 'D1' },
  ]),
  entities: makeDocs([
    { status: 'APPROVED' },
    { status: 'PENDING' },
  ]),
  trains: makeDocs([
    { status: 'ACTIVE', zone: 'Z1', division: 'D1' },
    { status: 'inactive', zone: 'Z1', division: 'D1' },
  ]),
  contracts: makeDocs([
    { status: 'ACTIVE' },
    { status: 'INACTIVE' },
  ]),
  coachForms: makeDocs([
    { status: 'SUBMITTED', submittedByZone: 'Z1', submittedByDivision: 'D1' },
    { status: 'APPROVED_BY_RAILWAY', submittedByZone: 'Z1', submittedByDivision: 'D1' },
    { status: 'LOCKED', submittedByZone: 'Z1', submittedByDivision: 'D1' },
    { status: 'AUTO_APPROVED', submittedByZone: 'Z1', submittedByDivision: 'D1' },
  ]),
  premisesForms: makeDocs([
    { status: 'SCORED', submittedByZone: 'Z1', submittedByDivision: 'D1' },
    { status: 'REJECTED', submittedByZone: 'Z1', submittedByDivision: 'D1' },
  ]),
  ctsForms: makeDocs([
    { status: 'DRAFT', submittedByZone: 'Z1', submittedByDivision: 'D1' },
  ]),
};

vi.mock('../src/database/index.js', () => {
  const coll = {};
  for (const [name, snap] of Object.entries(collections)) {
    coll[name] = snap;
  }

  const collectionMock = (name) => {
    const snap = coll[name] || makeDocs([]);
    let filtered = [...snap.docs];
    const q = {
      where(field, op, val) {
        filtered = filtered.filter(d => {
          const v = d.data()[field];
          if (op === '==') return v === val;
          return true;
        });
        return q;
      },
      get() {
        return Promise.resolve({
          docs: filtered,
          forEach(cb) { filtered.forEach(cb); },
          size: filtered.length,
          empty: filtered.length === 0,
        });
      }
    };
    return q;
  };
  return { db: { collection: collectionMock }, admin: {} };
});

describe('Dashboard Service - formsOverview data flow', () => {
  let dashboardService;

  beforeAll(async () => {
    const mod = await import('../src/services/dashboardService.js');
    dashboardService = mod.dashboardService;
  });

  it('returns formsOverview in getDashboardStats response', async () => {
    const result = await dashboardService.getDashboardStats(
      { role: 'super_admin', zone: 'Z1', division: 'D1' }
    );
    expect(result).toHaveProperty('formsOverview');
    expect(result.formsOverview).toHaveProperty('total');
    expect(result.formsOverview).toHaveProperty('pending');
    expect(result.formsOverview).toHaveProperty('manpowerApproved');
    expect(result.formsOverview).toHaveProperty('rejected');
    expect(result.formsOverview).toHaveProperty('scoringProgress');
    expect(result.formsOverview).toHaveProperty('autoApproved');
    expect(result.formsOverview).toHaveProperty('locked');
  });

  it('returns correct aggregated form counts', async () => {
    const result = await dashboardService.getDashboardStats(
      { role: 'super_admin' }
    );
    // coachForms: 1 SUBMITTED(pending) + 1 APPROVED_BY_RAILWAY(manpowerApproved) + 1 LOCKED + 1 AUTO_APPROVED
    // premisesForms: 1 SCORED(scoringProgress) + 1 REJECTED
    // ctsForms: 1 DRAFT(pending)
    expect(result.formsOverview.total).toBe(7);
    expect(result.formsOverview.pending).toBe(2);       // SUBMITTED + DRAFT
    expect(result.formsOverview.manpowerApproved).toBe(1); // APPROVED_BY_RAILWAY
    expect(result.formsOverview.rejected).toBe(1);       // REJECTED
    expect(result.formsOverview.scoringProgress).toBe(1); // SCORED
    expect(result.formsOverview.autoApproved).toBe(1);    // AUTO_APPROVED
    expect(result.formsOverview.locked).toBe(1);          // LOCKED
  });

  it('totalFormsProcessed matches formsOverview.total', async () => {
    const result = await dashboardService.getDashboardStats(
      { role: 'super_admin' }
    );
    expect(result.systemOverview.totalFormsProcessed).toBe(result.formsOverview.total);
  });

  it('applies zone filter to form queries when query param provided', async () => {
    const resultWithZone = await dashboardService.getDashboardStats(
      { role: 'super_admin' },
      { zone: 'Z1' }
    );
    expect(resultWithZone.formsOverview.total).toBe(7);
  });

  it('returns formsOverview with zone/division from requesterData when query not provided', async () => {
    const result = await dashboardService.getDashboardStats(
      { role: 'admin', zone: 'Z1', division: 'D1' }
    );
    expect(result.formsOverview).toBeDefined();
    expect(typeof result.formsOverview.total).toBe('number');
  });
});
