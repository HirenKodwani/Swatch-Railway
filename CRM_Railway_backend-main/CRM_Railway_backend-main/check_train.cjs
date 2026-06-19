const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();

async function checkTrain() {
  const snapshot = await db.collection('trains').where('trainNo', '==', '18451818').get();
  if (snapshot.empty) {
    console.log('Train 18451818 not found.');
    const all = await db.collection('trains').limit(50).get();
    all.forEach(doc => {
      if(doc.data().trainNo && doc.data().trainNo.includes('1845')) {
         console.log(doc.id, doc.data().trainNo, doc.data().days, doc.data().cycleLength, doc.data().requiredInstances);
      }
    });
  } else {
    snapshot.forEach(doc => {
      console.log('Train:', doc.id, doc.data().trainNo, doc.data().days, doc.data().cycleLength, doc.data().requiredInstances);
    });
  }
}
checkTrain().then(() => process.exit(0));
