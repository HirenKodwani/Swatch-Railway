import 'dotenv/config';
import admin from 'firebase-admin';

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

Promise.all([
  db.collection('coachForms').limit(1).get(),
  db.collection('premisesForms').limit(1).get(),
  db.collection('ctsForms').limit(1).get(),
  db.collection('cleaningForms').limit(1).get(),
  db.collection('task_instances').limit(1).get()
]).then(snaps => {
  console.log('coachForms size:', snaps[0].size);
  console.log('premisesForms size:', snaps[1].size);
  console.log('ctsForms size:', snaps[2].size);
  console.log('cleaningForms size:', snaps[3].size);
  console.log('task_instances size:', snaps[4].size);
  process.exit(0);
}).catch(e => {
  console.error(e);
  process.exit(1);
});
