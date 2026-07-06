export async function paginate(query, options = {}) {
  const pageSize = Math.min(200, Math.max(1, parseInt(options.limit) || 50));
  const orderBy = options.orderBy || 'createdAt';
  const orderDir = options.orderDir || 'desc';

  let q = options.cursor ? query.orderBy(orderBy, orderDir) : query;
  if (options.cursor) {
    q = q.startAfter(options.cursor);
  }

  q = q.limit(pageSize + 1);
  const snapshot = await q.get();
  const items = [];
  let count = 0;
  snapshot.forEach(doc => {
    count++;
    if (count <= pageSize) {
      items.push({ id: doc.id, ...doc.data() });
    }
  });

  if (!options.cursor) {
    const dir = orderDir === 'desc' ? -1 : 1;
    items.sort((a, b) => {
      const va = a[orderBy] || '';
      const vb = b[orderBy] || '';
      return va < vb ? -dir : va > vb ? dir : 0;
    });
  }

  const hasNext = count > pageSize;
  const lastItem = items.length > 0 ? items[items.length - 1] : null;
  const cursor = hasNext && lastItem ? lastItem[orderBy] : null;

  return {
    items,
    pagination: {
      count: items.length,
      hasNext,
      cursor,
      limit: pageSize
    }
  };
}
