import 'dotenv/config';
import admin from 'firebase-admin';

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const uid = 'worker-test-uid';

await db.collection('users').doc(uid).set({
  uid,
  fullName: 'Test Worker',
  email: 'worker@test.com',
  password: '123456',
  mobile: '9999999992',
  role: 'WORKER',
  userType: 'railway',
  zone: 'NR',
  division: 'DELHI',
  stationId: 'NxcYZkxeQxpwNWiyZQxy',
  status: 'APPROVED',
  createdAt: new Date().toISOString()
});

try {
  await admin.auth().createUser({
    uid,
    email: 'worker@test.com',
    password: '123456',
    displayName: 'Test Worker'
  });
  console.log('Firebase Auth user created');
} catch (e) {
  console.log('Firebase Auth user may already exist:', e.message);
}

console.log('WORKER user created: worker@test.com / 123456');
admin.app().delete();
