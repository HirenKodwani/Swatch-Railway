import { db } from './src/database/index.js';

async function test() {
  const snapshot = await db.collection('RunInstance').orderBy('createdAt', 'desc').limit(5).get();
  snapshot.forEach(doc => {
    console.log("ID:", doc.id);
    const data = doc.data();
    console.log("Train:", data.trainNo, "Div:", data.division, "Status:", data.status, "Created:", data.createdAt);
  });
  process.exit(0);
}
test();
