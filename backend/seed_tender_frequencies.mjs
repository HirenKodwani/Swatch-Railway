import admin from 'firebase-admin';
import { readFileSync } from 'fs';

const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT
  ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
  : JSON.parse(readFileSync('../crm_backend/serviceAccountKey.json', 'utf8'));

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const frequencies = [
  { name: 'Twenty Four Times a Day', type: 'twenty_four_times_daily', timesPerDay: 24, daysBetween: 0, order: 1 },
  { name: 'Eight Times a Day',        type: 'eight_times_daily',      timesPerDay: 8,  daysBetween: 0, order: 2 },
  { name: 'Six Times a Day',          type: 'six_times_daily',        timesPerDay: 6,  daysBetween: 0, order: 3 },
  { name: 'Four Times a Day',         type: 'four_times_daily',       timesPerDay: 4,  daysBetween: 0, order: 4 },
  { name: 'Three Times a Day',        type: 'three_times_daily',      timesPerDay: 3,  daysBetween: 0, order: 5 },
  { name: 'Two Times a Day',          type: 'twice_daily',            timesPerDay: 2,  daysBetween: 0, order: 6 },
  { name: 'Once a Day',               type: 'once_per_day',           timesPerDay: 1,  daysBetween: 0, order: 7 },
  { name: 'Six Times a Month',        type: 'six_times_monthly',      timesPerDay: 0,  daysBetween: 5, order: 8 },
  { name: 'Three Times a Month',      type: 'three_times_monthly',    timesPerDay: 0,  daysBetween: 10, order: 9 },
  { name: 'Two Times a Month',        type: 'twice_monthly',          timesPerDay: 0,  daysBetween: 15, order: 10 },
  { name: 'Once a Month',             type: 'monthly',                timesPerDay: 0,  daysBetween: 30, order: 11 },
  { name: 'As and When Required',     type: 'as_and_when_required',   timesPerDay: 0,  daysBetween: 0,  order: 12 },
];

for (const f of frequencies) {
  const ref = db.collection('frequencies').doc();
  await ref.set({
    uid: ref.id,
    frequencyName: f.name,
    frequencyType: f.type,
    timesPerDay: f.timesPerDay,
    daysBetween: f.daysBetween,
    description: `${f.name} cleaning frequency as per tender specification`,
    status: 'active',
    createdBy: 'system',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
  console.log(`Created frequency: ${f.name} (${ref.id})`);
}

console.log(`\nSeeded ${frequencies.length} tender frequencies.`);
admin.app().delete();
