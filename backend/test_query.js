import { db } from './src/database/index.js';

async function test() {
  const snapshot = await db.collection('users').get();
  const roles = new Set();
  snapshot.forEach(doc => {
    const data = doc.data();
    if (data.role) roles.add(data.role);
  });
  console.log("Roles:", Array.from(roles));
  process.exit(0);
}
test();
