import admin from 'firebase-admin';
import dotenv from 'dotenv';
import { resolve } from 'path';

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

const snapshot = await db.collection('stationAreas').get();
console.log(`Fetched ${snapshot.size} station areas:`);
snapshot.forEach(doc => {
  console.log(`- ID: ${doc.id}, data: ${JSON.stringify(doc.data())}`);
});

await admin.app().delete();
