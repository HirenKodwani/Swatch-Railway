import { db } from './backend/src/database/index.js';
import { runInstanceService } from './backend/src/services/runInstanceService.js';

async function test() {
  const result = await runInstanceService.getRunInstancesByDivision(null, null, true);
  console.log("Found instances:", result.count);
  if (result.count > 0) {
    console.log("Sample instance:", JSON.stringify(result.data[0], null, 2));
  } else {
    console.log("No instances found.");
  }
  process.exit(0);
}

test().catch(console.error);
