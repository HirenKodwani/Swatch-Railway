export function toCsv(rows) {
  return rows.map(r => r.map(c => {
    if (c === null || c === undefined) return '';
    const s = String(c);
    return s.includes(',') || s.includes('"') || s.includes('\n') ? `"${s.replace(/"/g, '""')}"` : s;
  }).join(',')).join('\n');
}

export function generateCsv(data, columns) {
  const header = columns.map(c => c.label || c.field);
  const rows = [header];
  data.forEach(item => {
    rows.push(columns.map(c => item[c.field] ?? ''));
  });
  return toCsv(rows);
}
