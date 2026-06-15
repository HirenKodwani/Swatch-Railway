import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Firebase-based OBHS data service.
/// Firestore Collections used:
///   obhsRunInstances  – one doc per run instance
///   obhsAttendance    – one doc per attendance mark (start/mid/end per worker)
///   obhsTasks         – one doc per task completion
///   obhsComplaints    – one doc per complaint raised
class FirebaseOBHSService {
  static final _db = FirebaseFirestore.instance;

  // ─── Collection Names ────────────────────────────────────────────────────
  static const String _runs = 'obhsRunInstances';
  static const String _attendance = 'obhsAttendance';
  static const String _tasks = 'obhsTasks';
  static const String _complaints = 'obhsComplaints';

  // ═══════════════════════════════════════════════════════════════════════════
  // RUN INSTANCES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save or update a run instance document in Firestore.
  /// Call this after a successful API creation so Firebase stays in sync.
  static Future<void> saveRunInstance(Map<String, dynamic> data) async {
    try {
      final docId = data['runInstanceId']?.toString() ??
          data['instanceId']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      await _db.collection(_runs).doc(docId).set({
        ...data,
        'savedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('[FirebaseOBHSService] saveRunInstance error: $e');
    }
  }

  /// Fetch all run instances, optionally filtered.
  static Future<List<Map<String, dynamic>>> getRunInstances({
    String? trainNo,
    String? status,
    DateTime? departureDate,
    DateTime? startDate,
    DateTime? endDate,
    String? zone,
    String? division,
  }) async {
    try {
      Query query = _db.collection(_runs);

      if (trainNo != null && trainNo.isNotEmpty) {
        query = query.where('trainNo', isEqualTo: trainNo);
      }
      if (status != null && status.isNotEmpty && status != 'All') {
        query = query.where('status', isEqualTo: status);
      }
      if (zone != null && zone.isNotEmpty) {
        query = query.where('zone', isEqualTo: zone);
      }
      if (division != null && division.isNotEmpty) {
        query = query.where('division', isEqualTo: division);
      }
      if (departureDate != null) {
        final depStr = DateFormat('yyyy-MM-dd').format(departureDate);
        query = query.where('departureDate', isEqualTo: depStr);
      }

      final snapshot = await query.get();
      var results = snapshot.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();

      if (startDate != null || endDate != null) {
        results = results.where((run) {
          final runDateStr = run['departureDate']?.toString() ?? '';
          if (runDateStr.isEmpty) return false;
          try {
            final runDate = DateFormat('yyyy-MM-dd').parse(runDateStr);
            if (startDate != null && runDate.isBefore(startDate)) return false;
            if (endDate != null && runDate.isAfter(endDate)) return false;
            return true;
          } catch (_) {
            return false;
          }
        }).toList();
      }

      return results;
    } catch (e) {
      print('[FirebaseOBHSService] getRunInstances error: $e');
      return [];
    }
  }

  /// Aggregate summary stats for the OBHS dashboard tab.
  static Future<Map<String, dynamic>> getOBHSStats({
    String? zone,
    String? division,
  }) async {
    try {
      Query query = _db.collection(_runs);
      if (zone != null && zone.isNotEmpty) {
        query = query.where('zone', isEqualTo: zone);
      }
      if (division != null && division.isNotEmpty) {
        query = query.where('division', isEqualTo: division);
      }

      final snapshot = await query.get();

      int totalInstances = snapshot.size;
      final Set<String> uniqueTrains = {};
      int activeInstances = 0;
      int pendingInstances = 0;
      int closedInstances = 0;
      int completedInstances = 0;
      int totalCoaches = 0;
      int coachesWithWorkers = 0;
      int totalWorkersAssigned = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final trainNo = data['trainNo']?.toString() ?? '';
        if (trainNo.isNotEmpty) uniqueTrains.add(trainNo);

        final status = (data['status'] ?? '').toString().toLowerCase();
        if (status == 'active') {
          activeInstances++;
        } else if (status == 'pending') {
          pendingInstances++;
        } else if (status == 'closed') {
          closedInstances++;
        } else if (status == 'completed') {
          completedInstances++;
        }

        final coaches = data['coaches'] as List<dynamic>? ?? [];
        totalCoaches += coaches.length;
        for (final c in coaches) {
          final cm = c as Map<String, dynamic>;
          final wId = cm['workerId']?.toString() ?? '';
          if (wId.isNotEmpty) {
            coachesWithWorkers++;
            totalWorkersAssigned++;
          }
        }
      }

      // Also count tasks as "Jobs Completed"
      final taskSnap = await _db
          .collection(_tasks)
          .where('status', isEqualTo: 'Completed')
          .get();

      return {
        'totalTrains': uniqueTrains.length,
        'totalInstances': totalInstances,
        'activeInstances': activeInstances,
        'pendingInstances': pendingInstances,
        'closedInstances': closedInstances,
        'completedInstances': completedInstances,
        'totalCoaches': totalCoaches,
        'coachesWithWorkers': coachesWithWorkers,
        'coachesWithoutWorkers': totalCoaches - coachesWithWorkers,
        'totalWorkersAssigned': totalWorkersAssigned,
        'jobsCompleted': taskSnap.size,
      };
    } catch (e) {
      print('[FirebaseOBHSService] getOBHSStats error: $e');
      return {
        'totalTrains': 0,
        'totalInstances': 0,
        'activeInstances': 0,
        'pendingInstances': 0,
        'closedInstances': 0,
        'completedInstances': 0,
        'totalCoaches': 0,
        'coachesWithWorkers': 0,
        'coachesWithoutWorkers': 0,
        'totalWorkersAssigned': 0,
        'jobsCompleted': 0,
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ATTENDANCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save attendance record to Firestore (call alongside existing API).
  static Future<void> saveAttendance(Map<String, dynamic> data) async {
    try {
      await _db.collection(_attendance).add({
        ...data,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('[FirebaseOBHSService] saveAttendance error: $e');
    }
  }

  /// Fetch attendance records for a specific run instance.
  static Future<List<Map<String, dynamic>>> getAttendanceForRun(
      String runInstanceId) async {
    try {
      final snapshot = await _db
          .collection(_attendance)
          .where('runInstanceId', isEqualTo: runInstanceId)
          .orderBy('attendanceTime', descending: false)
          .get();
      return snapshot.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
    } catch (e) {
      print('[FirebaseOBHSService] getAttendanceForRun error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TASKS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save task completion to Firestore (call alongside existing API).
  static Future<void> saveTask(Map<String, dynamic> data) async {
    try {
      await _db.collection(_tasks).add({
        ...data,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('[FirebaseOBHSService] saveTask error: $e');
    }
  }

  /// Fetch tasks for a specific run instance.
  static Future<List<Map<String, dynamic>>> getTasksForRun(
      String runInstanceId) async {
    try {
      final snapshot = await _db
          .collection(_tasks)
          .where('runInstanceId', isEqualTo: runInstanceId)
          .orderBy('completionTime', descending: false)
          .get();
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      print('[FirebaseOBHSService] getTasksForRun error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPLAINTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save complaint to Firestore (call alongside existing API).
  static Future<void> saveComplaint(Map<String, dynamic> data) async {
    try {
      await _db.collection(_complaints).add({
        ...data,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('[FirebaseOBHSService] saveComplaint error: $e');
    }
  }

  /// Fetch complaints for a specific run instance.
  static Future<List<Map<String, dynamic>>> getComplaintsForRun(
      String runInstanceId) async {
    try {
      final snapshot = await _db
          .collection(_complaints)
          .where('runInstanceId', isEqualTo: runInstanceId)
          .get();
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      print('[FirebaseOBHSService] getComplaintsForRun error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REPORT DATA BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get full report data for a run instance — combines all sub-collections.
  static Future<Map<String, dynamic>> getFullRunReportData(
      String runInstanceId) async {
    try {
      // Fetch the run instance doc
      final runSnap = await _db
          .collection(_runs)
          .where('runInstanceId', isEqualTo: runInstanceId)
          .limit(1)
          .get();

      Map<String, dynamic> runData = {};
      if (runSnap.docs.isNotEmpty) {
        runData = {'id': runSnap.docs.first.id, ...runSnap.docs.first.data()};
      }

      final attendance = await getAttendanceForRun(runInstanceId);
      final tasks = await getTasksForRun(runInstanceId);
      final complaints = await getComplaintsForRun(runInstanceId);

      return {
        'runInstance': runData,
        'attendance': attendance,
        'tasks': tasks,
        'complaints': complaints,
      };
    } catch (e) {
      print('[FirebaseOBHSService] getFullRunReportData error: $e');
      return {
        'runInstance': {},
        'attendance': [],
        'tasks': [],
        'complaints': [],
      };
    }
  }
}
