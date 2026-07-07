import 'dotenv/config';
import admin from 'firebase-admin';

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// Create a train first
const trainRef = db.collection('trains').doc('test-train-001');
await trainRef.set({
  trainNo: '12345',
  trainName: 'Test Express',
  zone: 'NR',
  division: 'DELHI',
  status: 'active',
  createdAt: new Date().toISOString()
});

// Create a TrainPair
const pairRef = db.collection('TrainPairs').doc('test-instance-001');
await pairRef.set({
  instanceId: 'test-instance-001',
  parentTrainId: 'test-train-001',
  trainNo: '12345',
  trainName: 'Test Express',
  inboundTrainNo: '12346',
  outboundTrainNo: '12345',
  zone: 'NR',
  division: 'DELHI',
  status: 'Active',
  journeyStartTime: '08:00:00',
  journeyEndTime: '20:00:00',
  createdAt: new Date().toISOString()
});

// Create RunInstance with worker assigned
const runRef = db.collection('RunInstance').doc();
await runRef.set({
  runInstanceId: runRef.id,
  instanceId: 'test-instance-001',
  departureDate: new Date().toISOString().split('T')[0],
  trainNo: '12345',
  trainName: 'Test Express',
  inboundTrainNo: '12346',
  outboundTrainNo: '12345',
  parentTrainId: 'test-train-001',
  division: 'DELHI',
  zone: 'NR',
  status: 'ACTIVE',
  numberOfCoaches: 1,
  coaches: [
    {
      coachPosition: 'S1',
      coachType: 'Sleeper',
      workerId: 'worker-test-uid',
      workerName: 'Test Worker',
      janitorId: 'worker-test-uid',
      janitorName: 'Test Worker',
      attendanceStatus: 'Pending'
    }
  ],
  attendanceCaptured: false,
  taskExecutionScore: 0,
  createdAt: new Date().toISOString(),
  createdBy: 'system',
  createdByName: 'System'
});

console.log(`RunInstance created: ${runRef.id}`);
console.log('Train: Test Express (12345)');
console.log('Worker: worker-test-uid assigned to coach S1');
admin.app().delete();
