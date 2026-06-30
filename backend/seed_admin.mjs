import admin from 'firebase-admin';
import { readFileSync } from 'fs';

const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT 
  ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT) 
  : JSON.parse(readFileSync('../crm_backend/serviceAccountKey.json', 'utf8'));

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// Create admin user with credentials: admin@gmail.com / 123456
await db.collection('users').doc('admin-uid').set({
  uid: 'admin-uid',
  fullName: 'Admin',
  email: 'admin@gmail.com',
  password: '123456',
  mobile: '9999999990',
  role: 'SUPER_ADMIN',
  userType: 'railway',
  zone: 'NR',
  division: 'DELHI',
  status: 'APPROVED',
  createdAt: new Date().toISOString()
});

// Also create in Firebase Auth so Firebase Auth features work
try {
  await admin.auth().createUser({
    uid: 'admin-uid',
    email: 'admin@gmail.com',
    password: '123456',
    displayName: 'Admin'
  });
  console.log('Firebase Auth user created');
} catch (e) {
  console.log('Firebase Auth user may already exist:', e.message);
}

console.log('Admin user created: admin@gmail.com / 123456');
admin.app().delete();
