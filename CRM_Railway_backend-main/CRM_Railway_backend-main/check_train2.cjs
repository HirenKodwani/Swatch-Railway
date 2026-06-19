const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();

async function checkTrain() {
  const all = await db.collection('trains').get();
  all.forEach(doc => {
    const data = doc.data();
    if(data.trainNo && String(data.trainNo).includes('1845')) {
       console.log('Train:', doc.id, data.trainNo, data.days, data.cycleLength, data.requiredInstances, data.outboundDurationStr, data.inboundDurationStr, data.layoverDestStr, data.layoverOriginStr);
    }
  });
}
checkTrain().then(() => process.exit(0));
