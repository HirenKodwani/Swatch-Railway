import { db } from './src/database/index.js';
import { runInstanceService } from './src/services/runInstanceService.js';

async function test() {
  try {
    const creatorData = {
      uid: 'test_admin_uid',
      name: 'Test Admin',
      role: 'super admin',
      division: 'MYS',
      zone: 'SWR'
    };

    // First find an active TrainPair to use as instanceId
    const pairsSnap = await db.collection('TrainPairs').limit(1).get();
    if (pairsSnap.empty) {
       console.log("No TrainPairs found to test with.");
       process.exit(0);
    }
    const pair = pairsSnap.docs[0];
    console.log("Using TrainPair:", pair.id);

    const body = {
      instanceId: pair.id,
      coaches: [
        { coachPosition: 'C01', coachType: 'AC', janitorId: 'test_worker_1', attendantId: 'test_worker_2' }
      ],
      departureDate: '2026-07-20'
    };

    const result = await runInstanceService.createRunInstance(creatorData, body);
    console.log("Success:", JSON.stringify(result, null, 2));

  } catch (error) {
    console.error("Failed:", error);
  } finally {
    process.exit(0);
  }
}

test();
