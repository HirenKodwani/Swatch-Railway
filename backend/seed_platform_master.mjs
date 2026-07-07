import 'dotenv/config';
import admin from 'firebase-admin';
import { readFileSync } from 'fs';

const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT 
  ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT) 
  : JSON.parse(readFileSync('../crm_backend/serviceAccountKey.json', 'utf8'));

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const uid = 'platform-master-uid';

await db.collection('users').doc(uid).set({
  uid,
  fullName: 'Platform Master',
  email: 'pm@test.com',
  password: '123456',
  mobile: '9999999991',
  role: 'PLATFORM_MASTER',
  userType: 'railway',
  zone: 'NR',
  division: 'DELHI',
  stationId: 'default-station',
  areaId: 'default-area',
  status: 'APPROVED',
  createdAt: new Date().toISOString()
});

try {
  await admin.auth().createUser({
    uid,
    email: 'pm@test.com',
    password: '123456',
    displayName: 'Platform Master'
  });
  console.log('Firebase Auth user created');
} catch (e) {
  console.log('Firebase Auth user may already exist:', e.message);
}

console.log('PLATFORM_MASTER user created: pm@test.com / 123456');
admin.app().delete();
