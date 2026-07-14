import admin from 'firebase-admin';
import dotenv from 'dotenv';
import { resolve } from 'path';

// Load .env
dotenv.config({ path: resolve('.env') });

const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT 
  ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT) 
  : null;

if (!serviceAccount) {
  console.error("FIREBASE_SERVICE_ACCOUNT env var not found");
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const snapshot = await db.collection('trains').get();
const trains = [];
snapshot.forEach(doc => {
  trains.push({ id: doc.id, ...doc.data() });
});
trains.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));

console.log(`Fetched ${trains.length} trains, showing 15 most recent:`);
trains.slice(0, 15).forEach(t => {
  console.log(`- UID: ${t.id}, trainNo: ${t.trainNo}, trainName: ${t.trainName}, status: ${t.status}, zone: ${t.zone}, division: ${t.division}, TrainApplicableFor: ${t.TrainApplicableFor}, createdAt: ${t.createdAt}`);
});

await admin.app().delete();
