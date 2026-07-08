import 'package:cloud_firestore/cloud_firestore.dart';

/// Seeds test OBHS data into Firestore for development/QA testing.
/// Call [seedAll()] once from a debug button.
class ObhsTestDataSeeder {
  static final _db = FirebaseFirestore.instance;

  // ─── Fixed IDs so re-seeding is idempotent ───────────────────────────────
  static const String _runId1 = 'RUN-TEST-1001';
  static const String _runId2 = 'RUN-TEST-1002';

  static Future<void> seedAll() async {
    await Future.wait([
      _seedRunInstances(),
      _seedAttendance(),
      _seedTasks(),
      _seedComplaints(),
    ]);
    print('[ObhsTestDataSeeder] All test data seeded successfully.');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RUN INSTANCES
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> _seedRunInstances() async {
    final now = DateTime.now();
    final instances = [
      {
        'runInstanceId': _runId1,
        'instanceId': 'SP-2026-001',
        'trainNo': '12356',
        'trainName': 'Rajdhani Express',
        'inboundTrainNo': '12355',
        'outboundTrainNo': '12356',
        'departureDate': '2026-06-08',
        'status': 'Active',
        'direction': 'Outbound (DOWN)',
        'baseStation': 'Jaipur',
        'destinationStation': 'Delhi',
        'journeyStartTime': '06:00 AM',
        'journeyEndTime': '06:30 PM',
        'journeyDuration': '12 Hours 30 Minutes',
        'supervisorName': 'Rakesh Sharma',
        'division': 'PCME Jaipur',
        'zone': 'NWR',
        'coaches': [
          {
            'coachPosition': 'B1',
            'coachNo': 'B1',
            'coachType': 'AC 3 Tier',
            'workerId': 'WRK-101',
            'workerName': 'Amit Sharma',
            'contractor': 'ABC Railway Services Pvt Ltd',
          },
          {
            'coachPosition': 'B2',
            'coachNo': 'B2',
            'coachType': 'AC 3 Tier',
            'workerId': 'WRK-102',
            'workerName': 'Ravi Verma',
            'contractor': 'ABC Railway Services Pvt Ltd',
          },
          {
            'coachPosition': 'A1',
            'coachNo': 'A1',
            'coachType': 'AC 2 Tier',
            'workerId': 'WRK-103',
            'workerName': 'Suresh Jain',
            'contractor': 'XYZ Cleaning Corp',
          },
          {
            'coachPosition': 'S3',
            'coachNo': 'S3',
            'coachType': 'Sleeper',
            'workerId': null,
            'workerName': null,
            'contractor': null,
          },
        ],
        'createdBy': 'admin-001',
        'createdByName': 'Admin User',
        'savedAt': FieldValue.serverTimestamp(),
      },
      {
        'runInstanceId': _runId2,
        'instanceId': 'SP-2026-002',
        'trainNo': '12001',
        'trainName': 'Shatabdi Express',
        'inboundTrainNo': '12002',
        'outboundTrainNo': '12001',
        'departureDate': '2026-06-07',
        'status': 'Closed',
        'direction': 'Inbound (UP)',
        'baseStation': 'New Delhi',
        'destinationStation': 'Bhopal',
        'journeyStartTime': '07:30 AM',
        'journeyEndTime': '02:00 PM',
        'journeyDuration': '6 Hours 30 Minutes',
        'supervisorName': 'Priya Singh',
        'division': 'PCME Delhi',
        'zone': 'NR',
        'coaches': [
          {
            'coachPosition': 'C1',
            'coachNo': 'C1',
            'coachType': 'CC Chair Car',
            'workerId': 'WRK-201',
            'workerName': 'Mukesh Kumar',
            'contractor': 'Clean India Services',
          },
          {
            'coachPosition': 'C2',
            'coachNo': 'C2',
            'coachType': 'CC Chair Car',
            'workerId': 'WRK-202',
            'workerName': 'Rohit Singh',
            'contractor': 'Clean India Services',
          },
        ],
        'createdBy': 'admin-001',
        'createdByName': 'Admin User',
        'savedAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final inst in instances) {
      await _db
          .collection('obhsRunInstances')
          .doc(inst['runInstanceId'] as String)
          .set(inst, SetOptions(merge: true));
    }
    print('[ObhsTestDataSeeder] Run instances seeded.');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ATTENDANCE
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> _seedAttendance() async {
    final records = [
      // Run 1 – Worker WRK-101 – Start
      {
        'runInstanceId': _runId1,
        'workerId': 'WRK-101',
        'workerName': 'Amit Sharma',
        'type': 'start',
        'attendanceType': 'start',
        'attendanceTime': '2026-06-08T06:00:00.000Z',
        'deviceTimestamp': '2026-06-08T06:00:12.000Z',
        'gpsLocation': '26.9124, 75.7873 (Jaipur Junction Platform 2)',
        'photoUrl': 'https://obhs-system/evidence/start1_wrk101.jpg',
        'syncStatus': 'Synced',
        'savedAt': FieldValue.serverTimestamp(),
      },
      // Run 1 – Worker WRK-101 – Mid
      {
        'runInstanceId': _runId1,
        'workerId': 'WRK-101',
        'workerName': 'Amit Sharma',
        'type': 'mid',
        'attendanceType': 'mid',
        'attendanceTime': '2026-06-08T12:15:00.000Z',
        'deviceTimestamp': '2026-06-08T12:15:18.000Z',
        'gpsLocation': '27.5530, 76.6346 (Near Coach B2)',
        'photoUrl': 'https://obhs-system/evidence/mid1_wrk101.jpg',
        'syncStatus': 'Synced',
        'savedAt': FieldValue.serverTimestamp(),
      },
      // Run 1 – Worker WRK-101 – End
      {
        'runInstanceId': _runId1,
        'workerId': 'WRK-101',
        'workerName': 'Amit Sharma',
        'type': 'end',
        'attendanceType': 'end',
        'attendanceTime': '2026-06-08T18:05:00.000Z',
        'deviceTimestamp': '2026-06-08T18:05:10.000Z',
        'gpsLocation': '28.6139, 77.2090 (Delhi Junction Platform 4)',
        'photoUrl': 'https://obhs-system/evidence/end1_wrk101.jpg',
        'syncStatus': 'Synced',
        'savedAt': FieldValue.serverTimestamp(),
      },
      // Run 1 – Worker WRK-102 – Start
      {
        'runInstanceId': _runId1,
        'workerId': 'WRK-102',
        'workerName': 'Ravi Verma',
        'type': 'start',
        'attendanceType': 'start',
        'attendanceTime': '2026-06-08T06:05:00.000Z',
        'deviceTimestamp': '2026-06-08T06:05:10.000Z',
        'gpsLocation': '26.9124, 75.7873 (Jaipur Junction Platform 2)',
        'photoUrl': 'https://obhs-system/evidence/start1_wrk102.jpg',
        'syncStatus': 'Synced',
        'savedAt': FieldValue.serverTimestamp(),
      },
      // Run 2 – Worker WRK-201 – Start
      {
        'runInstanceId': _runId2,
        'workerId': 'WRK-201',
        'workerName': 'Mukesh Kumar',
        'type': 'start',
        'attendanceType': 'start',
        'attendanceTime': '2026-06-07T07:30:00.000Z',
        'deviceTimestamp': '2026-06-07T07:30:05.000Z',
        'gpsLocation': '28.6419, 77.2220 (New Delhi Station Platform 1)',
        'photoUrl': 'https://obhs-system/evidence/start2_wrk201.jpg',
        'syncStatus': 'Synced',
        'savedAt': FieldValue.serverTimestamp(),
      },
    ];

    // Use doc IDs so re-seed is idempotent
    for (int i = 0; i < records.length; i++) {
      await _db
          .collection('obhsAttendance')
          .doc('ATT-TEST-${i + 1}')
          .set(records[i], SetOptions(merge: true));
    }
    print('[ObhsTestDataSeeder] Attendance records seeded.');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TASKS
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> _seedTasks() async {
    final tasks = [
      {
        'runInstanceId': _runId1,
        'taskId': 'TSK-1001',
        'workerId': 'WRK-101',
        'workerName': 'Amit Sharma',
        'taskCategory': 'Toilet Cleaning',
        'taskTitle': 'Toilet Cleaning',
        'coachNo': 'B1',
        'frequencyIndex': '1',
        'completionTime': '2026-06-08T07:10:00.000Z',
        'deviceTimestamp': '2026-06-08T07:10:00.000Z',
        'comment': 'Cleaning completed successfully',
        'beforePhotoUrl': 'https://obhs-system/evidence/task1001_before.jpg',
        'afterPhotoUrl': 'https://obhs-system/evidence/task1001_after.jpg',
        'status': 'Completed',
        'savedAt': FieldValue.serverTimestamp(),
      },
      {
        'runInstanceId': _runId1,
        'taskId': 'TSK-1002',
        'workerId': 'WRK-101',
        'workerName': 'Amit Sharma',
        'taskCategory': 'Garbage Handling',
        'taskTitle': 'Garbage Handling',
        'coachNo': 'B1',
        'frequencyIndex': '1',
        'completionTime': '2026-06-08T09:00:00.000Z',
        'deviceTimestamp': '2026-06-08T09:00:00.000Z',
        'comment': 'Dustbins cleared',
        'beforePhotoUrl': 'https://obhs-system/evidence/task1002_before.jpg',
        'afterPhotoUrl': 'https://obhs-system/evidence/task1002_after.jpg',
        'status': 'Completed',
        'savedAt': FieldValue.serverTimestamp(),
      },
      {
        'runInstanceId': _runId1,
        'taskId': 'TSK-1003',
        'workerId': 'WRK-101',
        'workerName': 'Amit Sharma',
        'taskCategory': 'Water Check',
        'taskTitle': 'Water Check',
        'coachNo': 'B1',
        'frequencyIndex': '1',
        'completionTime': '2026-06-08T12:20:00.000Z',
        'deviceTimestamp': '2026-06-08T12:20:00.000Z',
        'comment': 'Water availability verified',
        'beforePhotoUrl': 'https://obhs-system/evidence/task1003_before.jpg',
        'afterPhotoUrl': 'https://obhs-system/evidence/task1003_after.jpg',
        'status': 'Completed',
        'savedAt': FieldValue.serverTimestamp(),
      },
      {
        'runInstanceId': _runId1,
        'taskId': 'TSK-1004',
        'workerId': 'WRK-102',
        'workerName': 'Ravi Verma',
        'taskCategory': 'Mopping',
        'taskTitle': 'Mopping',
        'coachNo': 'B2',
        'frequencyIndex': '1',
        'completionTime': '2026-06-08T08:30:00.000Z',
        'deviceTimestamp': '2026-06-08T08:30:00.000Z',
        'comment': 'Floor mopped and cleaned',
        'beforePhotoUrl': 'https://obhs-system/evidence/task1004_before.jpg',
        'afterPhotoUrl': 'https://obhs-system/evidence/task1004_after.jpg',
        'status': 'Completed',
        'savedAt': FieldValue.serverTimestamp(),
      },
      {
        'runInstanceId': _runId2,
        'taskId': 'TSK-2001',
        'workerId': 'WRK-201',
        'workerName': 'Mukesh Kumar',
        'taskCategory': 'Toilet Cleaning',
        'taskTitle': 'Toilet Cleaning',
        'coachNo': 'C1',
        'frequencyIndex': '1',
        'completionTime': '2026-06-07T09:00:00.000Z',
        'deviceTimestamp': '2026-06-07T09:00:00.000Z',
        'comment': 'Toilet sanitised',
        'beforePhotoUrl': 'https://obhs-system/evidence/task2001_before.jpg',
        'afterPhotoUrl': 'https://obhs-system/evidence/task2001_after.jpg',
        'status': 'Completed',
        'savedAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final t in tasks) {
      await _db
          .collection('obhsTasks')
          .doc(t['taskId'] as String)
          .set(t, SetOptions(merge: true));
    }
    print('[ObhsTestDataSeeder] Tasks seeded.');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPLAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> _seedComplaints() async {
    final complaints = [
      {
        'runInstanceId': _runId1,
        'complaintId': 'CMP-2026-001',
        'workerId': 'WRK-102',
        'workerName': 'Ravi Verma',
        'coachNo': 'B2',
        'category': 'Equipment Failure',
        'type': 'CCTV Camera Not Working',
        'description':
            'CCTV camera installed near Coach B2 entrance is not recording footage. Display indicator remains off despite power supply being available. Passenger security monitoring may be affected.',
        'priority': 'HIGH',
        'status': 'IN PROGRESS',
        'gpsLocation': 'Near Coach B2 Entry Gate',
        'photoUrl': 'https://obhs-system/evidence/camera_issue_cmp001.jpg',
        'createdAt': '2026-06-08T10:15:00.000Z',
        'savedAt': FieldValue.serverTimestamp(),
      },
      {
        'runInstanceId': _runId2,
        'complaintId': 'CMP-2026-002',
        'workerId': 'WRK-201',
        'workerName': 'Mukesh Kumar',
        'coachNo': 'C1',
        'category': 'Sanitation Issue',
        'type': 'Water Leakage',
        'description':
            'Water leakage detected near the wash basin in Coach C1. The floor around the basin is wet, causing a slip hazard for passengers. Maintenance team should inspect the water pipe fittings.',
        'priority': 'NORMAL',
        'status': 'Resolved',
        'gpsLocation': 'Coach C1 Wash Basin Area',
        'photoUrl': null,
        'createdAt': '2026-06-07T10:45:00.000Z',
        'savedAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final c in complaints) {
      await _db
          .collection('obhsComplaints')
          .doc(c['complaintId'] as String)
          .set(c, SetOptions(merge: true));
    }
    print('[ObhsTestDataSeeder] Complaints seeded.');
  }

  /// Deletes all test data (documents with TEST- in their IDs).
  static Future<void> clearSeedData() async {
    final collections = ['obhsRunInstances', 'obhsAttendance', 'obhsTasks', 'obhsComplaints'];
    for (final col in collections) {
      final snap = await _db.collection(col).get();
      for (final doc in snap.docs) {
        if (doc.id.contains('TEST') || doc.id.contains('TSK-') || doc.id.contains('ATT-TEST') || doc.id.contains('CMP-')) {
          await doc.reference.delete();
        }
      }
    }
    print('[ObhsTestDataSeeder] Test data cleared.');
  }
}
