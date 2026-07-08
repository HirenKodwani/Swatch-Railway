import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import fs from 'fs';

const env = fs.readFileSync('/mnt/B6EACA0CEAC9C8B7/Railway/Swatch-Railway/backend/.env', 'utf8');
const vars = {};
env.split('\n').filter(l => l.trim() && !l.startsWith('#')).forEach(l => {
  const eq = l.indexOf('=');
  if (eq > 0) {
    let v = l.slice(eq + 1).trim();
    if (v.match(/^"[^"]*"$/)) v = v.slice(1, -1);
    vars[l.slice(0, eq).trim()] = v;
  }
});

const serviceAccount = JSON.parse(vars.FIREBASE_SERVICE_ACCOUNT);
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const users = [
  {
    uid: 'station-master-uid',
    fullName: 'Station Master',
    email: 'sm@test.com',
    mobile: '9999999993',
    role: 'STATION_MASTER',
    userType: 'railway',
    zone: 'NR',
    division: 'DELHI',
    stationId: 'NxcYZkxeQxpwNWiyZQxy',
    areaId: '',
    status: 'APPROVED',
    password: '123456',
    createdAt: new Date().toISOString(),
    activeRunInstanceId: null,
  },
  {
    uid: 'area-master-uid',
    fullName: 'Area Master',
    email: 'am@test.com',
    mobile: '9999999994',
    role: 'AREA_MASTER',
    userType: 'railway',
    zone: 'NR',
    division: 'DELHI',
    stationId: 'NxcYZkxeQxpwNWiyZQxy',
    areaId: '',
    status: 'APPROVED',
    password: '123456',
    createdAt: new Date().toISOString(),
    activeRunInstanceId: null,
  },
];

for (const user of users) {
  await db.collection('users').doc(user.uid).set(user);
  console.log(`Created ${user.role} (${user.email})`);
}

await db.collection('users').doc('platform-master-uid').update({
  stationId: 'NxcYZkxeQxpwNWiyZQxy',
  areaId: 'QeA9RsRSv3enYFIP2qUp',
});
console.log('Updated PLATFORM_MASTER with real station/area IDs');

console.log('DONE');
process.exit(0);
