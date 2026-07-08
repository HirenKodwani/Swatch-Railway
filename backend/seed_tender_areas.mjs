/*
 * Seed script for station cleaning tender area data.
 * Usage: node seed_tender_areas.mjs <stationId>
 * The station must already exist in the `stations` collection.
 */

import admin from 'firebase-admin';
import { readFileSync } from 'fs';

const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT
  ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
  : JSON.parse(readFileSync('../crm_backend/serviceAccountKey.json', 'utf8'));

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const stationId = process.argv[2];
if (!stationId) {
  console.error('Usage: node seed_tender_areas.mjs <stationId>');
  process.exit(1);
}

const stationDoc = await db.collection('stations').doc(stationId).get();
if (!stationDoc.exists) {
  console.error(`Station ${stationId} not found`);
  process.exit(1);
}
const stationName = stationDoc.data().stationName || 'Unknown';

const TENDER_AREAS = [
  // === Section 1: Platforms ===
  { section: 1, sectionName: 'Platforms', platformRef: 'PF-01', surfaceType: 'Kota stone flooring', areaSqft: 56187.56, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 224750.24 },
  { section: 1, sectionName: 'Platforms', platformRef: 'PF-02/03', surfaceType: 'Kota stone flooring', areaSqft: 72416.07, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 289664.28 },
  { section: 1, sectionName: 'Platforms', platformRef: 'PF-04/05', surfaceType: 'Kota stone flooring', areaSqft: 59309.09, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 118618.18 },

  // === Section 2: Cover Shed ===
  { section: 2, sectionName: 'Cover Shed', platformRef: 'PF-01', surfaceType: 'Roofing sheet', areaSqft: 39159.07, shiftConsidered: 'One time in a month and as and when required', tenderedAreaPerDay: 1286.54 },
  { section: 2, sectionName: 'Cover Shed', platformRef: 'PF-02/03', surfaceType: 'Roofing sheet', areaSqft: 64497.29, shiftConsidered: 'One time in a month and as and when required', tenderedAreaPerDay: 2119.01 },
  { section: 2, sectionName: 'Cover Shed', platformRef: 'PF-04/05', surfaceType: 'Roofing sheet', areaSqft: 9203.13, shiftConsidered: 'One time in a month and as and when required', tenderedAreaPerDay: 302.36 },

  // === Section 3: Cover Shed Valley Gutter ===
  { section: 3, sectionName: 'Cover Shed Valley Gutter', platformRef: 'PF-01', surfaceType: 'Valley Gutter', areaSqft: 1371.98, shiftConsidered: 'One time in a month and as and when required', tenderedAreaPerDay: 45.08 },
  { section: 3, sectionName: 'Cover Shed Valley Gutter', platformRef: 'PF-02/03', surfaceType: 'Valley Gutter', areaSqft: 1683.19, shiftConsidered: 'One time in a month and as and when required', tenderedAreaPerDay: 55.30 },
  { section: 3, sectionName: 'Cover Shed Valley Gutter', platformRef: 'PF-04/05', surfaceType: 'Valley Gutter', areaSqft: 294.04, shiftConsidered: 'One time in a month and as and when required', tenderedAreaPerDay: 9.66 },

  // === Section 4: New Station Building Ground Floor & First Floor ===
  // Clock Room
  { section: 4, sectionName: 'New Station Building', platformRef: 'Clock Room', surfaceType: 'Wall area', areaSqft: 421.71, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 27.71 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Clock Room', surfaceType: 'Floor Tiles area', areaSqft: 209.9, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 419.80 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Clock Room', surfaceType: 'False Ceiling area', areaSqft: 209.9, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 13.79 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Clock Room', surfaceType: 'Wall Granite area', areaSqft: 134.17, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 268.34 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Clock Room', surfaceType: 'Door area', areaSqft: 27.82, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 1.83 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Clock Room', surfaceType: 'Window panel area both side', areaSqft: 74.27, shiftConsidered: 'One time in a day and as and when required', tenderedAreaPerDay: 74.27 },
  // Electric Duty Room
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electric Duty Room', surfaceType: 'Wall area', areaSqft: 352.3, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 23.15 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electric Duty Room', surfaceType: 'Floor Tiles area', areaSqft: 123.78, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 247.56 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electric Duty Room', surfaceType: 'False Ceiling area', areaSqft: 123.78, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 8.13 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electric Duty Room', surfaceType: 'Wall Granite area', areaSqft: 91.12, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 182.24 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electric Duty Room', surfaceType: 'Door area', areaSqft: 27.82, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 1.83 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electric Duty Room', surfaceType: 'Window panel area both side', areaSqft: 38.1, shiftConsidered: 'One time in a day and as and when required', tenderedAreaPerDay: 38.10 },
  // Electric Store Room
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electric Store Room', surfaceType: 'Wall area', areaSqft: 287.77, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 18.91 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electric Store Room', surfaceType: 'Floor Tiles area', areaSqft: 207.1, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 414.20 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electric Store Room', surfaceType: 'False Ceiling area', areaSqft: 207.1, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 13.61 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electric Store Room', surfaceType: 'Wall Granite area', areaSqft: 92.84, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 185.68 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electric Store Room', surfaceType: 'Door area', areaSqft: 27.82, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 1.83 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electric Store Room', surfaceType: 'Window panel area both side', areaSqft: 111.41, shiftConsidered: 'One time in a day and as and when required', tenderedAreaPerDay: 111.41 },
  // ARME Room
  { section: 4, sectionName: 'New Station Building', platformRef: 'ARME Room', surfaceType: 'Wall area', areaSqft: 464.35, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 30.51 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'ARME Room', surfaceType: 'Floor Tiles area', areaSqft: 238.96, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 477.92 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'ARME Room', surfaceType: 'False Ceiling area', areaSqft: 238.96, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 15.70 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'ARME Room', surfaceType: 'Wall Granite area', areaSqft: 147.09, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 294.18 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'ARME Room', surfaceType: 'Door area', areaSqft: 27.82, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 1.83 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'ARME Room', surfaceType: 'Window panel area both side', areaSqft: 76.81, shiftConsidered: 'One time in a day and as and when required', tenderedAreaPerDay: 76.81 },
  // Engg. Room
  { section: 4, sectionName: 'New Station Building', platformRef: 'Engg. Room', surfaceType: 'Wall area', areaSqft: 276.41, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 18.16 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Engg. Room', surfaceType: 'Floor Tiles area', areaSqft: 86.65, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 173.30 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Engg. Room', surfaceType: 'False Ceiling area', areaSqft: 86.65, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 5.69 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Engg. Room', surfaceType: 'Wall Granite area', areaSqft: 46.82, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 93.64 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Engg. Room', surfaceType: 'Door area', areaSqft: 27.82, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 1.83 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Engg. Room', surfaceType: 'Window panel area both side', areaSqft: 25.83, shiftConsidered: 'One time in a day and as and when required', tenderedAreaPerDay: 25.83 },
  // Staircase
  { section: 4, sectionName: 'New Station Building', platformRef: 'Staircase', surfaceType: 'Wall area', areaSqft: 128.2, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 8.42 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Staircase', surfaceType: 'Floor Tiles area', areaSqft: 193.7, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 774.80 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Staircase', surfaceType: 'Ceiling area', areaSqft: 63.51, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 4.17 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Staircase', surfaceType: 'Wall Granite area', areaSqft: 555.42, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 1110.84 },
  // Passage area 2.8m wide
  { section: 4, sectionName: 'New Station Building', platformRef: 'Passage 2.8m', surfaceType: 'Wall area', areaSqft: 636.87, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 41.85 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Passage 2.8m', surfaceType: 'Floor Tiles area', areaSqft: 287.72, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 1150.88 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Passage 2.8m', surfaceType: 'False Ceiling area', areaSqft: 287.72, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 18.91 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Passage 2.8m', surfaceType: 'Wall Granite area', areaSqft: 108.72, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 217.44 },
  // VIP Room
  { section: 4, sectionName: 'New Station Building', platformRef: 'VIP Room', surfaceType: 'Wall area', areaSqft: 1282.17, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 84.25 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'VIP Room', surfaceType: 'Floor Tiles area', areaSqft: 824.41, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 3297.64 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'VIP Room', surfaceType: 'False Ceiling area', areaSqft: 665.21, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 43.71 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'VIP Room', surfaceType: 'Ceiling area', areaSqft: 159.2, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 318.40 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'VIP Room', surfaceType: 'Wall Granite area', areaSqft: 234.6, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 469.20 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'VIP Room', surfaceType: 'Wall Tiles area', areaSqft: 548.49, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 1096.98 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'VIP Room', surfaceType: 'Window panel area both side', areaSqft: 92.35, shiftConsidered: 'One time in a day and as and when required', tenderedAreaPerDay: 92.35 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'VIP Room', surfaceType: 'Door area', areaSqft: 140.66, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 9.24 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'VIP Room', surfaceType: 'Ventilation', areaSqft: 4.35, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 8.70 },
  // SS Room
  { section: 4, sectionName: 'New Station Building', platformRef: 'SS Room', surfaceType: 'Wall area', areaSqft: 960.21, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 63.09 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SS Room', surfaceType: 'Floor Tiles area', areaSqft: 463.93, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 1855.72 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SS Room', surfaceType: 'Ceiling area', areaSqft: 55.44, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 3.64 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SS Room', surfaceType: 'False Ceiling area', areaSqft: 408.49, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 816.98 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SS Room', surfaceType: 'Wall Granite area', areaSqft: 210.06, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 420.12 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SS Room', surfaceType: 'Wall Tiles area', areaSqft: 315.17, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 630.34 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SS Room', surfaceType: 'Window panel area both side', areaSqft: 38.1, shiftConsidered: 'One time in a day and as and when required', tenderedAreaPerDay: 38.10 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SS Room', surfaceType: 'Door area', areaSqft: 84.78, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 5.57 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SS Room', surfaceType: 'Ventilation', areaSqft: 8.65, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 17.30 },
  // SM Room
  { section: 4, sectionName: 'New Station Building', platformRef: 'SM Room', surfaceType: 'Wall area', areaSqft: 938.08, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 61.64 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SM Room', surfaceType: 'Floor Tiles area', areaSqft: 689.75, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 2759.00 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SM Room', surfaceType: 'Ceiling area', areaSqft: 36.81, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 2.42 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SM Room', surfaceType: 'False Ceiling area', areaSqft: 652.94, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 1305.88 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SM Room', surfaceType: 'Wall Granite area', areaSqft: 298.7, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 597.40 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SM Room', surfaceType: 'Wall Tiles area', areaSqft: 145.51, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 291.02 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SM Room', surfaceType: 'Window panel area both side', areaSqft: 76.21, shiftConsidered: 'One time in a day and as and when required', tenderedAreaPerDay: 76.21 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SM Room', surfaceType: 'Door area', areaSqft: 46.89, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 3.08 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'SM Room', surfaceType: 'Ventilation', areaSqft: 4.33, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 8.66 },
  // CBS Room
  { section: 4, sectionName: 'New Station Building', platformRef: 'CBS Room', surfaceType: 'Wall area', areaSqft: 1152.52, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 75.73 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'CBS Room', surfaceType: 'Floor Tiles area', areaSqft: 533.7, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 2134.80 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'CBS Room', surfaceType: 'Ceiling area', areaSqft: 501.17, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 32.93 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'CBS Room', surfaceType: 'False Ceiling area', areaSqft: 32.53, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 65.06 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'CBS Room', surfaceType: 'Wall Granite area', areaSqft: 351.98, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 703.96 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'CBS Room', surfaceType: 'Wall Tiles area', areaSqft: 157.58, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 315.16 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'CBS Room', surfaceType: 'Window panel area both side', areaSqft: 29.57, shiftConsidered: 'One time in a day and as and when required', tenderedAreaPerDay: 29.57 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'CBS Room', surfaceType: 'Door area', areaSqft: 96.06, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 6.31 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'CBS Room', surfaceType: 'Ventilation', areaSqft: 4.33, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 8.66 },
  // Booking Office
  { section: 4, sectionName: 'New Station Building', platformRef: 'Booking Office', surfaceType: 'Wall area', areaSqft: 906.25, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 59.55 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Booking Office', surfaceType: 'Floor Tiles area', areaSqft: 423.02, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 846.04 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Booking Office', surfaceType: 'False Ceiling area', areaSqft: 423.02, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 27.80 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Booking Office', surfaceType: 'Wall Granite area', areaSqft: 287.15, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 574.30 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Booking Office', surfaceType: 'Window/Glass area both side', areaSqft: 332.86, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 665.72 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Booking Office', surfaceType: 'Door area', areaSqft: 98.53, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 6.47 },
  // Passenger Concourse
  { section: 4, sectionName: 'New Station Building', platformRef: 'Passenger Concourse', surfaceType: 'Wall area', areaSqft: 1486.82, shiftConsidered: 'Three times in a month and as and when required', tenderedAreaPerDay: 3.05 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Passenger Concourse', surfaceType: 'Wall Granite area', areaSqft: 123.52, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 494.08 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Passenger Concourse', surfaceType: 'Floor Italian Marble area', areaSqft: 2823.34, shiftConsidered: 'Six times in a month and as and when required', tenderedAreaPerDay: 16940.04 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Passenger Concourse', surfaceType: 'Ceiling area', areaSqft: 1060.76, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 69.70 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Passenger Concourse', surfaceType: 'Main door glass (entry/exit)', areaSqft: 792.22, shiftConsidered: 'Three times in a day and as and when required', tenderedAreaPerDay: 2376.66 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Passenger Concourse', surfaceType: 'Window panel area both side', areaSqft: 57.16, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 114.32 },
  // Toilet F&M
  { section: 4, sectionName: 'New Station Building', platformRef: 'Toilet F&M', surfaceType: 'Wall area', areaSqft: 1104.38, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 72.57 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Toilet F&M', surfaceType: 'Floor Tiles area', areaSqft: 831.82, shiftConsidered: 'Eight times in a day and as and when required', tenderedAreaPerDay: 6654.56 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Toilet F&M', surfaceType: 'Ceiling area', areaSqft: 831.82, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 54.66 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Toilet F&M', surfaceType: 'Wall Tiles area', areaSqft: 1868.79, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 7475.16 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Toilet F&M', surfaceType: 'Ventilation', areaSqft: 34.62, shiftConsidered: 'Three times in a day and as and when required', tenderedAreaPerDay: 103.86 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Toilet F&M', surfaceType: 'Door area', areaSqft: 207.46, shiftConsidered: 'Three times in a month and as and when required', tenderedAreaPerDay: 20.45 },
  // Deluxe Non-AC Waiting
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe Non-AC Waiting', surfaceType: 'Wall area', areaSqft: 1254.17, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 82.41 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe Non-AC Waiting', surfaceType: 'Floor Tiles area', areaSqft: 1011.97, shiftConsidered: 'Six times in a day and as and when required', tenderedAreaPerDay: 6071.82 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe Non-AC Waiting', surfaceType: 'False Ceiling area', areaSqft: 735.82, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 48.35 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe Non-AC Waiting', surfaceType: 'Ceiling area', areaSqft: 276.82, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 18.19 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe Non-AC Waiting', surfaceType: 'Wall Granite area', areaSqft: 241.11, shiftConsidered: 'Six times in a day and as and when required', tenderedAreaPerDay: 1446.66 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe Non-AC Waiting', surfaceType: 'Wall Tiles area', areaSqft: 991.36, shiftConsidered: 'Six times in a day and as and when required', tenderedAreaPerDay: 5948.16 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe Non-AC Waiting', surfaceType: 'Window panel area both side', areaSqft: 76.21, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 152.42 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe Non-AC Waiting', surfaceType: 'Door area', areaSqft: 207.46, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 13.63 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe Non-AC Waiting', surfaceType: 'Ventilation', areaSqft: 21.64, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 43.28 },
  // Deluxe AC Waiting
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe AC Waiting', surfaceType: 'Wall area', areaSqft: 1254.17, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 82.41 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe AC Waiting', surfaceType: 'Floor Tiles area', areaSqft: 1011.97, shiftConsidered: 'Six times in a day and as and when required', tenderedAreaPerDay: 6071.82 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe AC Waiting', surfaceType: 'False Ceiling area', areaSqft: 735.82, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 48.35 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe AC Waiting', surfaceType: 'Ceiling area', areaSqft: 276.15, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 18.15 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe AC Waiting', surfaceType: 'Wall Granite area', areaSqft: 241.11, shiftConsidered: 'Six times in a day and as and when required', tenderedAreaPerDay: 1446.66 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe AC Waiting', surfaceType: 'Wall Tiles area', areaSqft: 991.36, shiftConsidered: 'Six times in a day and as and when required', tenderedAreaPerDay: 5948.16 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe AC Waiting', surfaceType: 'Window panel area both side', areaSqft: 76.21, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 152.42 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe AC Waiting', surfaceType: 'Door area', areaSqft: 207.46, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 13.63 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Deluxe AC Waiting', surfaceType: 'Ventilation', areaSqft: 21.64, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 43.28 },
  // Electrical Panel Room
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electrical Panel Room', surfaceType: 'Wall area', areaSqft: 1255.56, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 82.50 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electrical Panel Room', surfaceType: 'Floor Tiles area', areaSqft: 797.44, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 1594.88 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electrical Panel Room', surfaceType: 'Ceiling area', areaSqft: 797.44, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 52.40 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electrical Panel Room', surfaceType: 'Wall Granite area', areaSqft: 430.59, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 861.18 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electrical Panel Room', surfaceType: 'Window panel area both side', areaSqft: 152.42, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 304.84 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Electrical Panel Room', surfaceType: 'Door area', areaSqft: 29.21, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 1.92 },
  // Care Taker Room
  { section: 4, sectionName: 'New Station Building', platformRef: 'Care Taker Room', surfaceType: 'Wall area', areaSqft: 1139.77, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 74.89 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Care Taker Room', surfaceType: 'Floor Tiles area', areaSqft: 1037.91, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 2075.82 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Care Taker Room', surfaceType: 'False Ceiling area', areaSqft: 252.41, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 16.59 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Care Taker Room', surfaceType: 'Ceiling area', areaSqft: 785.5, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 51.61 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Care Taker Room', surfaceType: 'Wall Tiles area', areaSqft: 114.51, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 229.02 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Care Taker Room', surfaceType: 'Wall Granite area', areaSqft: 372.81, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 745.62 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Care Taker Room', surfaceType: 'Window panel area both side', areaSqft: 190.52, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 381.04 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Care Taker Room', surfaceType: 'Ventilation', areaSqft: 4.33, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 8.66 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Care Taker Room', surfaceType: 'Door area', areaSqft: 51.49, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 3.38 },
  // Supervisor Rest House 1
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-1', surfaceType: 'Wall area', areaSqft: 786.73, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 51.69 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-1', surfaceType: 'Floor Tiles area', areaSqft: 421.82, shiftConsidered: 'Six times in a day and as and when required', tenderedAreaPerDay: 2530.92 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-1', surfaceType: 'False Ceiling area', areaSqft: 367.26, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 24.13 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-1', surfaceType: 'Ceiling area', areaSqft: 54.47, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 3.58 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-1', surfaceType: 'Wall Tiles area', areaSqft: 204.92, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 409.84 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-1', surfaceType: 'Wall Granite area', areaSqft: 226.04, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 452.08 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-1', surfaceType: 'Window panel area both side', areaSqft: 38.1, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 76.20 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-1', surfaceType: 'Ventilation', areaSqft: 4.33, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 8.66 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-1', surfaceType: 'Door area', areaSqft: 51.49, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 3.38 },
  // Supervisor Rest House 2
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-2', surfaceType: 'Wall area', areaSqft: 786.73, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 51.69 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-2', surfaceType: 'Floor Tiles area', areaSqft: 421.82, shiftConsidered: 'Six times in a day and as and when required', tenderedAreaPerDay: 2530.92 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-2', surfaceType: 'False Ceiling area', areaSqft: 367.26, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 24.13 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-2', surfaceType: 'Ceiling area', areaSqft: 54.47, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 3.58 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-2', surfaceType: 'Wall Tiles area', areaSqft: 204.92, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 409.84 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-2', surfaceType: 'Wall Granite area', areaSqft: 226.04, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 452.08 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-2', surfaceType: 'Window panel area both side', areaSqft: 38.1, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 76.20 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-2', surfaceType: 'Ventilation', areaSqft: 4.33, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 8.66 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Rest House-2', surfaceType: 'Door area', areaSqft: 51.49, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 3.38 },
  // 1st Floor Common Toilet
  { section: 4, sectionName: 'New Station Building', platformRef: '1st Floor Common Toilet', surfaceType: 'Wall area', areaSqft: 558.11, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 36.67 },
  { section: 4, sectionName: 'New Station Building', platformRef: '1st Floor Common Toilet', surfaceType: 'Floor Tiles area', areaSqft: 300.31, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 1201.24 },
  { section: 4, sectionName: 'New Station Building', platformRef: '1st Floor Common Toilet', surfaceType: 'Ceiling area', areaSqft: 300.31, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 19.73 },
  { section: 4, sectionName: 'New Station Building', platformRef: '1st Floor Common Toilet', surfaceType: 'Wall Tiles area', areaSqft: 871.34, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 3485.36 },
  { section: 4, sectionName: 'New Station Building', platformRef: '1st Floor Common Toilet', surfaceType: 'Ventilation', areaSqft: 17.22, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 34.44 },
  { section: 4, sectionName: 'New Station Building', platformRef: '1st Floor Common Toilet', surfaceType: 'Door area', areaSqft: 88.59, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 5.82 },
  // CCTV/Security/VSS/RPF Room
  { section: 4, sectionName: 'New Station Building', platformRef: 'CCTV/Security/VSS/RPF', surfaceType: 'Wall area', areaSqft: 805.25, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 52.91 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'CCTV/Security/VSS/RPF', surfaceType: 'Floor Tiles area', areaSqft: 738.83, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 1477.66 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'CCTV/Security/VSS/RPF', surfaceType: 'False Ceiling area', areaSqft: 738.83, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 48.55 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'CCTV/Security/VSS/RPF', surfaceType: 'Wall Granite area', areaSqft: 272, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 544.00 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'CCTV/Security/VSS/RPF', surfaceType: 'Window panel area both side', areaSqft: 152.42, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 304.84 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'CCTV/Security/VSS/RPF', surfaceType: 'Door area', areaSqft: 29.21, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 1.92 },
  // Supervisor Cabin & Departments
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Cabin & Departments', surfaceType: 'Wall area', areaSqft: 3117.98, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 204.88 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Cabin & Departments', surfaceType: 'Floor Tiles area', areaSqft: 1621.46, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 6485.84 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Cabin & Departments', surfaceType: 'Ceiling area', areaSqft: 1621.46, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 106.54 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Cabin & Departments', surfaceType: 'Wall Granite area', areaSqft: 708.76, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 1417.52 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Cabin & Departments', surfaceType: 'Window panel area both side', areaSqft: 457.25, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 914.50 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Supervisor Cabin & Departments', surfaceType: 'Door area', areaSqft: 130.22, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 8.56 },
  // Officer Rest House 1
  { section: 4, sectionName: 'New Station Building', platformRef: 'Officer Rest House-1', surfaceType: 'Wall area', areaSqft: 867.87, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 57.03 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Officer Rest House-1', surfaceType: 'Floor Tiles area', areaSqft: 476.53, shiftConsidered: 'Six times in a day and as and when required', tenderedAreaPerDay: 2859.18 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Officer Rest House-1', surfaceType: 'False Ceiling area', areaSqft: 383.19, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 25.18 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Officer Rest House-1', surfaceType: 'Ceiling area', areaSqft: 93.33, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 6.13 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Officer Rest House-1', surfaceType: 'Wall Tiles area', areaSqft: 372.78, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 745.56 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Officer Rest House-1', surfaceType: 'Wall Granite area', areaSqft: 184.06, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 368.12 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Officer Rest House-1', surfaceType: 'Window panel area both side', areaSqft: 67.81, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 135.62 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Officer Rest House-1', surfaceType: 'Ventilation', areaSqft: 4.33, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 8.66 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'Officer Rest House-1', surfaceType: 'Door area', areaSqft: 77.5, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 5.09 },
  // OFC/MPLS/LT/Battery
  { section: 4, sectionName: 'New Station Building', platformRef: 'OFC/MPLS/LT/Battery', surfaceType: 'Wall area', areaSqft: 1089.23, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 71.57 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'OFC/MPLS/LT/Battery', surfaceType: 'Floor Tiles area', areaSqft: 1502.21, shiftConsidered: 'Once in a day and as and when required', tenderedAreaPerDay: 1502.21 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'OFC/MPLS/LT/Battery', surfaceType: 'False Ceiling area', areaSqft: 1502.21, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 98.71 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'OFC/MPLS/LT/Battery', surfaceType: 'Wall Granite area', areaSqft: 392.18, shiftConsidered: 'Once in a day and as and when required', tenderedAreaPerDay: 392.18 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'OFC/MPLS/LT/Battery', surfaceType: 'Window panel area both side', areaSqft: 495.35, shiftConsidered: 'Once in a day and as and when required', tenderedAreaPerDay: 495.35 },
  { section: 4, sectionName: 'New Station Building', platformRef: 'OFC/MPLS/LT/Battery', surfaceType: 'Door area', areaSqft: 29.71, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 1.95 },
  // 1.8M Passage
  { section: 4, sectionName: 'New Station Building', platformRef: '1.8M Passage/Staircase', surfaceType: 'Wall area', areaSqft: 5226.64, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 343.43 },
  { section: 4, sectionName: 'New Station Building', platformRef: '1.8M Passage/Staircase', surfaceType: 'Floor Tiles area', areaSqft: 1855.93, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 7423.72 },
  { section: 4, sectionName: 'New Station Building', platformRef: '1.8M Passage/Staircase', surfaceType: 'Ceiling area', areaSqft: 3033.4, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 199.32 },
  { section: 4, sectionName: 'New Station Building', platformRef: '1.8M Passage/Staircase', surfaceType: 'Wall Granite area', areaSqft: 1633.66, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 6534.64 },
  { section: 4, sectionName: 'New Station Building', platformRef: '1.8M Passage/Staircase', surfaceType: 'Window panel & glass door', areaSqft: 2235.43, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 4470.86 },
  // Wall Painting
  { section: 4, sectionName: 'New Station Building', platformRef: 'All Interior Walls', surfaceType: 'Wall painting area', areaSqft: 30981.59, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 2035.75 },

  // === Section 5: RPF Building ===
  { section: 5, sectionName: 'RPF Building', platformRef: 'RPF Office', surfaceType: 'Ceiling area', areaSqft: 1130.21, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 74.26 },
  { section: 5, sectionName: 'RPF Building', platformRef: 'RPF Office', surfaceType: 'Floor Tiles area', areaSqft: 1130.21, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 2260.42 },
  { section: 5, sectionName: 'RPF Building', platformRef: 'RPF Toilet', surfaceType: 'Floor Tiles area', areaSqft: 127.55, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 510.20 },

  // === Section 13: Tracks ===
  { section: 13, sectionName: 'Tracks', platformRef: 'Track-01', surfaceType: 'Track area', areaSqft: 26258.53, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 105034.12 },
  { section: 13, sectionName: 'Tracks', platformRef: 'Track-02', surfaceType: 'Track area', areaSqft: 26258.53, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 105034.12 },
  { section: 13, sectionName: 'Tracks', platformRef: 'Track-03', surfaceType: 'Track area', areaSqft: 26258.53, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 105034.12 },
  { section: 13, sectionName: 'Tracks', platformRef: 'Track-04', surfaceType: 'Track area', areaSqft: 26258.53, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 105034.12 },
  { section: 13, sectionName: 'Tracks', platformRef: 'Track-05', surfaceType: 'Track area', areaSqft: 21720.04, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 86880.16 },
  { section: 13, sectionName: 'Tracks', platformRef: 'Track-06', surfaceType: 'Track area', areaSqft: 21720.04, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 86880.16 },
  { section: 13, sectionName: 'Tracks', platformRef: 'Track-07', surfaceType: 'Track area', areaSqft: 66021.46, shiftConsidered: 'Three times in a day and as and when required', tenderedAreaPerDay: 198064.38 },
  { section: 13, sectionName: 'Tracks', platformRef: 'Track-08', surfaceType: 'Track area', areaSqft: 66021.46, shiftConsidered: 'Three times in a day and as and when required', tenderedAreaPerDay: 198064.38 },

  // === Section 14: FOB & Drains ===
  { section: 14, sectionName: 'FOB & Drains', platformRef: 'Cover Shed area', surfaceType: 'General area', areaSqft: 15414.24, shiftConsidered: 'Once in a month and as and when required', tenderedAreaPerDay: 506.42 },
  { section: 14, sectionName: 'FOB & Drains', platformRef: 'FOB Staircase', surfaceType: 'Staircase area', areaSqft: 10667.72, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 42670.88 },
  { section: 14, sectionName: 'FOB & Drains', platformRef: 'FOB Floor', surfaceType: 'Floor area', areaSqft: 3444.45, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 13777.80 },

  // === Section 15: Circulating Area ===
  { section: 15, sectionName: 'Circulating Area', platformRef: 'Circulation & Approach', surfaceType: 'Open area', areaSqft: 54901.08, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 219604.32 },

  // === Section 17: Platform Walls ===
  { section: 17, sectionName: 'Platform Walls', platformRef: 'PF-01', surfaceType: 'Wall area', areaSqft: 11935.01, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 784.23 },

  // === Section 18: Benches ===
  { section: 18, sectionName: 'Benches', platformRef: 'PF-01', surfaceType: 'Bench surface', areaSqft: 486.51, shiftConsidered: 'Three times in a day and as and when required', tenderedAreaPerDay: 1459.53 },
  { section: 18, sectionName: 'Benches', platformRef: 'PF-02/03', surfaceType: 'Bench surface', areaSqft: 866.45, shiftConsidered: 'Three times in a day and as and when required', tenderedAreaPerDay: 2599.35 },
  { section: 18, sectionName: 'Benches', platformRef: 'PF-04/05', surfaceType: 'Bench surface', areaSqft: 128.84, shiftConsidered: 'Three times in a day and as and when required', tenderedAreaPerDay: 386.52 },

  // === Section 19: Drinking Water Fountains ===
  { section: 19, sectionName: 'Water Fountains', platformRef: 'PF-01', surfaceType: 'Water fountain', areaSqft: 476.3, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 1905.20 },
  { section: 19, sectionName: 'Water Fountains', platformRef: 'PF-02/03', surfaceType: 'Water fountain', areaSqft: 555.69, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 2222.76 },
  { section: 19, sectionName: 'Water Fountains', platformRef: 'PF-04/05', surfaceType: 'Water fountain', areaSqft: 238.15, shiftConsidered: 'Four times in a day and as and when required', tenderedAreaPerDay: 952.60 },

  // === Section 20: Toilet Blocks on PF ===
  { section: 20, sectionName: 'Toilet Blocks on PF', platformRef: 'PF-01', surfaceType: 'Flooring', areaSqft: 312.15, shiftConsidered: 'Twenty Four times in a day and as and when required', tenderedAreaPerDay: 7491.60 },
  { section: 20, sectionName: 'Toilet Blocks on PF', platformRef: 'PF-01', surfaceType: 'Ceiling', areaSqft: 312.15, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 20.51 },
  { section: 20, sectionName: 'Toilet Blocks on PF', platformRef: 'PF-02/03', surfaceType: 'Flooring', areaSqft: 161.46, shiftConsidered: 'Twenty Four times in a day and as and when required', tenderedAreaPerDay: 3875.04 },
  { section: 20, sectionName: 'Toilet Blocks on PF', platformRef: 'PF-02/03', surfaceType: 'Ceiling', areaSqft: 161.46, shiftConsidered: 'Two times in a month and as and when required', tenderedAreaPerDay: 10.61 },

  // === Section 21: Toilet Block Walls on PF ===
  { section: 21, sectionName: 'Toilet Block Walls on PF', platformRef: 'PF-01', surfaceType: 'Wall area', areaSqft: 798.14, shiftConsidered: 'Three times in a month and as and when required', tenderedAreaPerDay: 78.67 },
  { section: 21, sectionName: 'Toilet Block Walls on PF', platformRef: 'PF-02/03', surfaceType: 'Wall area', areaSqft: 1383.38, shiftConsidered: 'Three times in a month and as and when required', tenderedAreaPerDay: 136.35 },

  // === Section 22: Water Fountain Walls ===
  { section: 22, sectionName: 'Water Fountain Walls', platformRef: 'PF-01', surfaceType: 'Wall area', areaSqft: 138.53, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 277.06 },
  { section: 22, sectionName: 'Water Fountain Walls', platformRef: 'PF-02/03', surfaceType: 'Wall area', areaSqft: 161.62, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 323.24 },
  { section: 22, sectionName: 'Water Fountain Walls', platformRef: 'PF-04/05', surfaceType: 'Wall area', areaSqft: 69.27, shiftConsidered: 'Two times in a day and as and when required', tenderedAreaPerDay: 138.54 },

  // === Section 28: Garden & Misc ===
  { section: 28, sectionName: 'Garden & Misc', platformRef: 'RPF Yard PF-1', surfaceType: 'Garden area', areaSqft: 6242.09, shiftConsidered: 'Once in a day and as and when required', tenderedAreaPerDay: 6242.09 },
  { section: 28, sectionName: 'Garden & Misc', platformRef: 'Community Hall PF-1', surfaceType: 'Open area', areaSqft: 23092.12, shiftConsidered: 'Once in a day and as and when required', tenderedAreaPerDay: 23092.12 },
  { section: 28, sectionName: 'Garden & Misc', platformRef: 'PWI Office Front PF-1', surfaceType: 'Open area', areaSqft: 10768.1, shiftConsidered: 'Once in a day and as and when required', tenderedAreaPerDay: 10768.10 },
  { section: 28, sectionName: 'Garden & Misc', platformRef: 'ADEN Office Front PF-1', surfaceType: 'Open area', areaSqft: 11898.74, shiftConsidered: 'Once in a day and as and when required', tenderedAreaPerDay: 11898.74 },
  { section: 28, sectionName: 'Garden & Misc', platformRef: 'Misc Remaining', surfaceType: 'Open area', areaSqft: 10763.9, shiftConsidered: 'Once in a day and as and when required', tenderedAreaPerDay: 10763.90 },
];

let count = 0;
for (const area of TENDER_AREAS) {
  const ref = db.collection('areas').doc();
  const areaName = `${area.sectionName} - ${area.platformRef} (${area.surfaceType})`;
  const data = {
    uid: ref.id,
    stationId,
    stationName,
    areaName,
    areaType: _inferAreaType(area.sectionName, area.surfaceType),
    frequency: _inferFrequency(area.shiftConsidered),
    priority: area.tenderedAreaPerDay > 50000 ? 1 : area.tenderedAreaPerDay > 10000 ? 2 : 3,
    status: 'active',
    section: area.section,
    sectionName: area.sectionName,
    platformRef: area.platformRef,
    surfaceType: area.surfaceType,
    areaSqft: area.areaSqft,
    shiftConsidered: area.shiftConsidered,
    tenderedAreaPerDay: area.tenderedAreaPerDay,
    createdBy: 'system',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  await ref.set(data);
  count++;
  if (count % 20 === 0) console.log(`  ${count} areas seeded...`);
}

function _inferAreaType(sectionName, surfaceType) {
  const s = (sectionName + ' ' + surfaceType).toLowerCase();
  if (s.includes('toilet')) return 'Toilet';
  if (s.includes('track')) return 'Track';
  if (s.includes('fob') || s.includes('staircase')) return 'FOB';
  if (s.includes('waiting')) return 'Waiting Hall';
  if (s.includes('bench')) return 'Other';
  if (s.includes('water') || s.includes('fountain')) return 'Water Booth';
  if (s.includes('parking') || s.includes('circulating') || s.includes('approach')) return 'Circulating Area';
  if (s.includes('garden')) return 'Gardens';
  if (s.includes('drain')) return 'Drains';
  if (s.includes('office') || s.includes('room') || s.includes('cabin')) return 'Office';
  if (s.includes('concourse') || s.includes('passage') || s.includes('hall')) return 'Concourse';
  if (s.includes('platform') || s.includes('pf')) return 'Platform';
  return 'Other';
}

function _inferFrequency(shiftConsidered) {
  const s = (shiftConsidered || '').toLowerCase();
  if (s.includes('twenty four')) return 'twenty_four_times_daily';
  if (s.includes('eight')) return 'eight_times_daily';
  if (s.includes('six') && s.includes('day')) return 'six_times_daily';
  if (s.includes('four')) return 'four_times_daily';
  if (s.includes('three') && s.includes('day')) return 'three_times_daily';
  if (s.includes('two') && s.includes('day')) return 'twice_daily';
  if (s.includes('once') && s.includes('day')) return 'once_per_day';
  if (s.includes('six') && s.includes('month')) return 'six_times_monthly';
  if (s.includes('three') && s.includes('month')) return 'three_times_monthly';
  if (s.includes('two') && s.includes('month')) return 'twice_monthly';
  if (s.includes('once') && s.includes('month') || s.includes('one') && s.includes('month')) return 'monthly';
  return 'as_and_when_required';
}

console.log(`\nSeeded ${count} tender areas for station "${stationName}" (${stationId})`);
admin.app().delete();
