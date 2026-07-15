import admin from 'firebase-admin';
import { readFileSync, existsSync } from 'fs';

let serviceAccount;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
} else {
  let keyPath = 'C:\\Users\\ADMIN\\Downloads\\Swatch-Railway-final\\swachh-railways-firebase-adminsdk-fbsvc-d426e8d428.json';
  serviceAccount = JSON.parse(readFileSync(keyPath, 'utf8'));
}

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

async function seedForms() {
  console.log("Seeding dummy forms for dashboard pie charts...");
  
  const statuses = [
    'SUBMITTED', 'APPROVED_BY_RAILWAY', 'SCORING_IN_PROGRESS', 
    'LOCKED', 'AUTO_APPROVED', 'REJECTED_BY_RAILWAY', 'RE-SUBMITTED', 'SCORED'
  ];

  const collections = ['coachForms', 'premisesForms', 'ctsForms'];
  const commonZone = "Central Railway";
  const commonDivision = "Mumbai";

  for (const collection of collections) {
    for (const status of statuses) {
      // Create 2 forms for each status
      for (let i = 0; i < 2; i++) {
        const id = `${collection}-${status}-${i}-${Date.now()}`;
        const formData = {
          uid: id,
          status: status,
          zone: commonZone,
          division: commonDivision,
          submittedByZone: commonZone,
          submittedByDivision: commonDivision,
          depot: 'CSMT',
          createdAt: new Date().toISOString(),
          contractorName: "Demo Contractor",
          score: 85,
          trainInfo: { 'Train Name': 'Demo Train' }
        };

        if (collection === 'ctsForms') {
          formData.trainInfo = { trainName: 'Demo Train', trainNo: '12345' };
        } else if (collection === 'premisesForms') {
          formData.premisesName = 'Demo Premises';
        }

        await db.collection(collection).doc(id).set(formData);
      }
    }
    console.log(`Seeded 16 forms for ${collection}`);
  }

  console.log("Database forms seeding completed successfully!");
}

seedForms()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
