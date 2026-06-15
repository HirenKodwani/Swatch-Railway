// lib/controllers/worker_controller.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user_model.dart';
import '../model/worker_profile_model.dart';
import '../repositories/worker_repo.dart';
import '../services/firebase_obhs_service.dart';

class WorkerController extends GetxController {
  final isLoading = false.obs;
  final isStartLoading = false.obs;
  final isMidLoading = false.obs;
  final isEndLoading = false.obs;
  final isProfileLoading = false.obs;
  final isStatsLoading = false.obs;
  final errorMessage = ''.obs;

  final Rx<WorkerProfileModel?> workerProfile = Rx<WorkerProfileModel?>(null);

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  String get workerName =>
      workerProfile.value?.fullName ?? currentUser.value?.fullName ?? '';
  String get workerEmail =>
      workerProfile.value?.email ?? currentUser.value?.email ?? '';
  String get workerPhone =>
      workerProfile.value?.mobile ?? currentUser.value?.mobile ?? '';
  String get workerRole => currentUser.value?.role ?? '';
  String get workerStatus =>
      workerProfile.value?.status ?? currentUser.value?.status ?? '';
  String get designation =>
      workerProfile.value?.designation ?? currentUser.value?.designation ?? '';
  String get assignedZone =>
      workerProfile.value?.zone ?? currentUser.value?.zone ?? '';
  String get assignedDivision =>
      workerProfile.value?.division ?? currentUser.value?.division ?? '';
  String get assignedDepot => currentUser.value?.depot ?? '';
  List<AssignedRun> get assignedRuns => workerProfile.value?.assignedRuns ?? [];

  String get trainNo =>
      attendanceRun?.trainNo ??
      (assignedRuns.isNotEmpty ? assignedRuns.first.trainNo : '');
  String get trainName =>
      attendanceRun?.trainName ??
      (assignedRuns.isNotEmpty ? assignedRuns.first.trainName : '');
  String get instanceId =>
      attendanceRun?.instanceId ??
      (assignedRuns.isNotEmpty ? assignedRuns.first.instanceId : '');
  String get runStatus =>
      attendanceRun?.status ??
      (assignedRuns.isNotEmpty ? assignedRuns.first.status : '');

  AssignedRun? get attendanceRun {
    final validRuns = assignedRuns
        .where((run) => run.runInstanceId.trim().isNotEmpty)
        .toList();
    if (validRuns.isEmpty) return null;

    for (final run in validRuns) {
      final status = run.status.toLowerCase();
      if (status == 'scheduled' || status == 'active') {
        return run;
      }
    }

    return validRuns.first;
  }

  List<String> get assignedCoaches {
    return assignedRuns
        .where((r) => r.myCoach != null)
        .map((r) => r.myCoach!.coachType)
        .toList();
  }

  final tasksCompleted = 0.obs;
  final attendancePercentage = 0.obs;
  final complaintsRaised = 0.obs;
  final averageRating = 0.obs;

  final dueTasks = 0.obs;
  final overdueTasks = 0.obs;
  final completedTasks = 0.obs;
  final upcomingTasks = 0.obs;

  final startAttendance = false.obs;
  final midCheckin = false.obs;
  final endAttendance = false.obs;

  int get totalAssignedTasks =>
      dueTasks.value +
      overdueTasks.value +
      completedTasks.value +
      upcomingTasks.value;

  bool get hasCompletedMinimumForMid => completedTasks.value >= 3;

  bool get hasCompletedMinimumForEnd =>
      totalAssignedTasks > 0 && completedTasks.value >= totalAssignedTasks;

  static const _kProfile = 'worker_profile_cache';
  static const _kProfileTs = 'worker_profile_cache_ts';
  static const _kStats = 'worker_stats_cache';
  static const _kAttendanceDate = 'worker_attendance_date';
  static const _kStartAttendanceMarked = 'worker_start_attendance_marked';
  static const _kMidAttendanceMarked = 'worker_mid_attendance_marked';
  static const _kEndAttendanceMarked = 'worker_end_attendance_marked';

  static const _cacheTtlMs = 10 * 60 * 1000;

  @override
  void onInit() {
    super.onInit();
    _restoreFromCache();
  }

  void setUser(UserModel user) {
    currentUser.value = user;
    workerProfile.refresh();

    _printCurrentAuthToken();
    _restoreAttendanceState();
    _loadProfileSmartly().then((_) => refreshAttendanceStatus());
    loadWorkerStatistics();
  }

  Future<void> _restoreAttendanceState() async {
    final prefs = await SharedPreferences.getInstance();
    await _restoreTodayAttendanceState(prefs);
  }

  Future<void> _printCurrentAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    debugPrint('\n======= CURRENT WORKER AUTH TOKEN =======');
    debugPrint(token ?? 'No token found in SharedPreferences');
    debugPrint('=========================================\n');
  }

  Future<void> _restoreFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kProfile);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        workerProfile.value = WorkerProfileModel.fromJson(decoded);
      }

      final statsRaw = prefs.getString(_kStats);
      if (statsRaw != null) {
        final s = jsonDecode(statsRaw) as Map<String, dynamic>;
        _applyStats(s);
      }
      await _restoreTodayAttendanceState(prefs);
    } catch (_) {}
  }

  Future<void> _restoreTodayAttendanceState(SharedPreferences prefs) async {
    final savedDate = prefs.getString(_kAttendanceDate);
    if (savedDate != _todayKey) {
      await prefs.remove(_kStartAttendanceMarked);
      await prefs.remove(_kMidAttendanceMarked);
      await prefs.remove(_kEndAttendanceMarked);
      return;
    }

    startAttendance.value = prefs.getBool(_kStartAttendanceMarked) ?? false;
    midCheckin.value = prefs.getBool(_kMidAttendanceMarked) ?? false;
    endAttendance.value = prefs.getBool(_kEndAttendanceMarked) ?? false;
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveAttendanceState(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAttendanceDate, _todayKey);

    if (type == 'start') {
      await prefs.setBool(_kStartAttendanceMarked, true);
    } else if (type == 'mid') {
      await prefs.setBool(_kMidAttendanceMarked, true);
    } else if (type == 'end') {
      await prefs.setBool(_kEndAttendanceMarked, true);
    }
  }

  Future<void> _saveAttendanceSnapshot({
    required bool start,
    required bool mid,
    required bool end,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAttendanceDate, _todayKey);
    await prefs.setBool(_kStartAttendanceMarked, start);
    await prefs.setBool(_kMidAttendanceMarked, mid);
    await prefs.setBool(_kEndAttendanceMarked, end);
  }

  Future<void> _saveProfileToCache(Map<String, dynamic> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfile, jsonEncode(json));
      await prefs.setInt(_kProfileTs, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> _saveStatsToCache(Map<String, dynamic> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kStats, jsonEncode(json));
    } catch (_) {}
  }

  Future<void> _clearProfileCacheOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProfile);
      await prefs.remove(_kProfileTs);
    } catch (_) {}
  }

  Future<bool> _isCacheStale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt(_kProfileTs) ?? 0;
      return DateTime.now().millisecondsSinceEpoch - ts > _cacheTtlMs;
    } catch (_) {
      return true;
    }
  }

  Future<void> _loadProfileSmartly() async {
    final stale = await _isCacheStale();
    if (!stale &&
        workerProfile.value != null &&
        workerProfile.value!.assignedRuns.isNotEmpty) {
      return;
    }

    await _fetchProfileFromApi();
  }

  Future<void> _fetchProfileFromApi() async {
    try {
      isProfileLoading.value = true;
      errorMessage.value = '';

      final response = await WorkerRepository.getWorkerProfile();

      if (response['success'] == true) {
        workerProfile.value = WorkerProfileModel.fromJson(response);
        _applyAttendanceStateFromProfile();

        await _saveProfileToCache(response);
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      errorMessage.value = msg;

      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
    } finally {
      isProfileLoading.value = false;
    }
  }

  Future<AssignedRun?> _refreshAttendanceRunFromApi() async {
    final response = await WorkerRepository.getWorkerProfile();
    if (response['success'] == true) {
      workerProfile.value = WorkerProfileModel.fromJson(response);
      _applyAttendanceStateFromProfile();
      await _saveProfileToCache(response);
      return attendanceRun;
    }
    return null;
  }

  Future<String?> _resolveAttendanceRunInstanceId() async {
    final currentRunId = attendanceRun?.runInstanceId.trim();
    if (currentRunId != null && currentRunId.isNotEmpty) {
      return currentRunId;
    }

    final response = await WorkerRepository.getWorkerProfile();
    if (response['success'] == true) {
      workerProfile.value = WorkerProfileModel.fromJson(response);
      _applyAttendanceStateFromProfile();
      await _saveProfileToCache(response);
    }

    final runs = response['assignedRuns'];
    if (runs is! List || runs.isEmpty) return attendanceRun?.runInstanceId;

    Map<String, dynamic>? fallbackRun;
    for (final rawRun in runs) {
      if (rawRun is! Map) continue;
      final run = Map<String, dynamic>.from(rawRun);
      final runInstanceId = (run['runInstanceId'] ?? run['id'])?.toString();
      if (runInstanceId == null || runInstanceId.trim().isEmpty) continue;

      fallbackRun ??= run;
      final status = run['status']?.toString().toLowerCase() ?? '';
      if (status == 'scheduled' || status == 'active') {
        return runInstanceId.trim();
      }
    }

    return (fallbackRun?['runInstanceId'] ?? fallbackRun?['id'])?.toString();
  }

  void _applyAttendanceStateFromProfile() {
    // Profile status must NEVER set attendance flags.
    // The only authoritative sources are:
    //   1. markAttendanceAction() → local prefs (same day)
    //   2. refreshAttendanceStatus() → API with date check
    // Calling this from profile fetch risks persisting yesterday's status.
    // INTENTIONALLY NO-OP — kept for safety.
    debugPrint('_applyAttendanceStateFromProfile: skipped (date-safe mode).');
  }

  Future<void> refreshAttendanceStatus() async {
    try {
      final runInstanceId = await _resolveAttendanceRunInstanceId();
      if (runInstanceId == null || runInstanceId.trim().isEmpty) return;

      final response = await WorkerRepository.getObhsAttendanceStatus(
        runInstanceId: runInstanceId,
      );
      await _applyAttendanceStatusResponse(response);
    } catch (e) {
      debugPrint('Attendance status restore failed: $e');
    }
  }

  Future<void> _applyAttendanceStatusResponse(
    Map<String, dynamic> response,
  ) async {
    final statusPayload = _statusPayload(response);

    // ── DATE GUARD (Primary: API date) ──────────────────────────────────────
    final attendanceDate = _extractAttendanceDate(response, statusPayload);
    if (attendanceDate != null) {
      final attendanceDayKey =
          '${attendanceDate.year}-${attendanceDate.month.toString().padLeft(2, '0')}-${attendanceDate.day.toString().padLeft(2, '0')}';
      if (attendanceDayKey != _todayKey) {
        debugPrint(
          '[Attendance] API date $attendanceDayKey != today $_todayKey. Clearing.',
        );
        await _resetAttendancePrefs();
        return;
      }
      // Date from API is today — fall through to apply status.
    } else {
      // ── DATE GUARD (Fallback: local SharedPreferences date) ────────────────
      // The backend didn't include a date in its response.
      // Trust the LOCAL prefs: if the worker hasn't marked attendance today
      // on this device, treat the API result as stale (from a previous day)
      // and refuse to apply it.
      final isLocallyConfirmedToday = await _isTodayAttendanceLocallyStored();
      if (!isLocallyConfirmedToday) {
        debugPrint(
          '[Attendance] No API date and no local today-date. Treating as stale. Clearing.',
        );
        await _resetAttendancePrefs();
        return;
      }
      // Local prefs confirm today → fall through to apply status.
    }
    // ─────────────────────────────────────────────────────────────────────────

    final hasStart =
        _truthy(statusPayload, [
          'start',
          'startAttendance',
          'startMarked',
          'isStartMarked',
          'startSubmitted',
          'isStartSubmitted',
        ]) ||
        _statusStringContains(statusPayload, ['start', 'present']);
    final hasMid =
        _truthy(statusPayload, [
          'mid',
          'midCheckin',
          'midAttendance',
          'midSubmitted',
          'isMidMarked',
          'isMidSubmitted',
        ]) ||
        _statusStringContains(statusPayload, ['mid']);
    final hasEnd =
        _truthy(statusPayload, [
          'end',
          'endAttendance',
          'endSubmitted',
          'isEndMarked',
          'isEndSubmitted',
        ]) ||
        _statusStringContains(statusPayload, ['end']);

    final startMarked = hasStart || hasMid || hasEnd;
    final midMarked = hasMid || hasEnd;
    final endMarked = hasEnd;

    startAttendance.value = startMarked;
    midCheckin.value = midMarked;
    endAttendance.value = endMarked;

    await _saveAttendanceSnapshot(
      start: startMarked,
      mid: midMarked,
      end: endMarked,
    );
  }

  /// Returns true only if today's attendance date is stored in SharedPreferences,
  /// meaning the worker already marked some attendance TODAY on this device.
  Future<bool> _isTodayAttendanceLocallyStored() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(_kAttendanceDate);
      return savedDate == _todayKey;
    } catch (_) {
      return false;
    }
  }

  /// Clears all attendance flags in memory and SharedPreferences.
  Future<void> _resetAttendancePrefs() async {
    startAttendance.value = false;
    midCheckin.value = false;
    endAttendance.value = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kStartAttendanceMarked);
      await prefs.remove(_kMidAttendanceMarked);
      await prefs.remove(_kEndAttendanceMarked);
      await prefs.remove(_kAttendanceDate);
    } catch (_) {}
  }

  /// Tries to extract a meaningful timestamp from the API attendance response.
  /// Returns null when no recognisable date field is found.
  DateTime? _extractAttendanceDate(
    Map<String, dynamic> response,
    dynamic statusPayload,
  ) {
    // Common field names where the backend might put the date
    const dateFields = [
      'date',
      'attendanceDate',
      'startTime',
      'startedAt',
      'createdAt',
      'updatedAt',
      'timestamp',
      'markedAt',
    ];

    // Search in the top-level response first, then in the status payload
    for (final source in [response, if (statusPayload is Map) statusPayload]) {
      if (source is! Map) continue;
      for (final field in dateFields) {
        final raw = source[field];
        if (raw == null) continue;
        if (raw is String && raw.isNotEmpty) {
          final parsed = DateTime.tryParse(raw);
          if (parsed != null) return parsed.toLocal();
        }
        if (raw is int && raw > 0) {
          final ms = raw < 10000000000 ? raw * 1000 : raw;
          return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
        }
      }
    }
    return null;
  }

  dynamic _statusPayload(Map<String, dynamic> response) {
    return response['attendance'] ??
        response['attendanceStatus'] ??
        response['status'] ??
        response['data'] ??
        response;
  }

  bool _truthy(dynamic source, List<String> keys) {
    if (source is! Map) return false;
    for (final key in keys) {
      final value = source[key];
      if (value == true) return true;
      if (value is num && value > 0) return true;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true' ||
            lower == 'submitted' ||
            lower == 'marked' ||
            lower == 'done' ||
            lower == 'completed') {
          return true;
        }
      }
    }
    return false;
  }

  bool _statusStringContains(dynamic source, List<String> values) {
    if (source is! String) return false;
    final lower = source.toLowerCase();
    return values.any(lower.contains);
  }

  Future<String?> resolveRunInstanceId() => _resolveAttendanceRunInstanceId();

  Future<XFile> _captureAttendancePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
      maxWidth: 1280,
    );

    if (photo == null) {
      throw Exception('Attendance photo is required.');
    }

    return photo;
  }

  Future<Position> _getAttendanceLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Please enable location services to mark attendance.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission is required to mark attendance.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it from settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> loadWorkerProfile() async {
    await _fetchProfileFromApi();
  }

  Future<void> loadWorkerStatistics() async {
    try {
      isStatsLoading.value = true;
      errorMessage.value = '';

      final response = await WorkerRepository.getWorkerStatistics();

      if (response['success'] == true && response['statistics'] != null) {
        final stats = response['statistics'] as Map<String, dynamic>;
        _applyStats(stats);
        await _saveStatsToCache(stats);
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isStatsLoading.value = false;
    }
  }

  void _applyStats(Map<String, dynamic> stats) {
    dueTasks.value = stats['dueTasks'] ?? dueTasks.value;
    overdueTasks.value = stats['overdueTasks'] ?? overdueTasks.value;
    completedTasks.value = stats['completedTasks'] ?? completedTasks.value;
    upcomingTasks.value = stats['upcomingTasks'] ?? upcomingTasks.value;
    tasksCompleted.value = stats['tasksCompleted'] ?? tasksCompleted.value;
    attendancePercentage.value =
        stats['attendancePercentage'] ?? attendancePercentage.value;
    complaintsRaised.value =
        stats['complaintsRaised'] ?? complaintsRaised.value;
    averageRating.value = stats['averageRating'] ?? averageRating.value;
  }

  void syncTaskBoardCounts({
    required int due,
    required int overdue,
    required int completed,
    required int upcoming,
  }) {
    dueTasks.value = due;
    overdueTasks.value = overdue;
    completedTasks.value = completed;
    upcomingTasks.value = upcoming;
    tasksCompleted.value = completed;
  }

  bool canMarkAttendance(String type) {
    switch (type) {
      case 'start':
        return !startAttendance.value;
      case 'mid':
        return startAttendance.value &&
            !midCheckin.value &&
            hasCompletedMinimumForMid;
      case 'end':
        return startAttendance.value &&
            midCheckin.value &&
            !endAttendance.value &&
            hasCompletedMinimumForEnd;
      default:
        return false;
    }
  }

  String attendanceLockReason(String type) {
    switch (type) {
      case 'mid':
        if (!startAttendance.value) {
          return 'Mark start attendance first';
        }
        if (!hasCompletedMinimumForMid) {
          return 'Complete 3 tasks to unlock';
        }
        return 'Ready for mid check-in';
      case 'end':
        if (!startAttendance.value) {
          return 'Mark start attendance first';
        }
        if (!midCheckin.value) {
          return 'Mark mid check-in first';
        }
        if (totalAssignedTasks == 0) {
          return 'Load assigned tasks first';
        }
        if (!hasCompletedMinimumForEnd) {
          return 'Complete all assigned tasks to unlock';
        }
        return 'Ready for end attendance';
      default:
        return 'Mark your start time';
    }
  }

  Future<bool> markAttendanceAction(String type) async {
    try {
      if (type == 'start') isStartLoading.value = true;
      if (type == 'mid') isMidLoading.value = true;
      if (type == 'end') isEndLoading.value = true;
      isLoading.value = true;
      errorMessage.value = '';

      if (!canMarkAttendance(type)) {
        throw Exception(attendanceLockReason(type));
      }

      var runInstanceId = await _resolveAttendanceRunInstanceId();

      if (runInstanceId == null || runInstanceId.trim().isEmpty) {
        await _clearProfileCacheOnly();
        await _refreshAttendanceRunFromApi();
        runInstanceId = await _resolveAttendanceRunInstanceId();
      }

      if (runInstanceId == null || runInstanceId.trim().isEmpty) {
        throw Exception('No run instance assigned for attendance.');
      }

      final photo = await _captureAttendancePhoto();
      final position = await _getAttendanceLocation();
      final imageUrl = await WorkerRepository.uploadMedia(photo.path);

      final response = await WorkerRepository.markAttendance(
        type: type,
        runInstanceId: runInstanceId,
        imageUrl: imageUrl,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final isSuccess =
          response['success'] == true ||
          response['message'] != null ||
          response['attendance'] != null ||
          response['data'] != null;
      final responseMessage = response['message']?.toString() ?? '';
      final isAlreadySubmitted =
          responseMessage.toLowerCase().contains('already') &&
          responseMessage.toLowerCase().contains('submitted');

      if (isSuccess || isAlreadySubmitted) {
        if (type == 'start') startAttendance.value = true;
        if (type == 'mid') midCheckin.value = true;
        if (type == 'end') endAttendance.value = true;
        await _saveAttendanceState(type);
        await refreshAttendanceStatus();

        // ── Mirror to Firestore for report generation ────────────────────
        FirebaseOBHSService.saveAttendance({
          'runInstanceId': runInstanceId,
          'workerId': workerProfile.value?.uid ?? '',
          'workerName': workerProfile.value?.fullName ?? '',
          'type': type,
          'attendanceType': type,
          'attendanceTime': DateTime.now().toIso8601String(),
          'deviceTimestamp': DateTime.now().toIso8601String(),
          'gpsLocation': '${position.latitude}, ${position.longitude}',
          'photoUrl': imageUrl,
          'syncStatus': 'Synced',
        });

        Get.snackbar(
          isAlreadySubmitted ? 'Already Submitted' : 'Success',
          isAlreadySubmitted
              ? responseMessage
              : 'Attendance marked successfully',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        await loadWorkerStatistics();
        return true;
      }

      throw Exception(
        response['message'] ??
            response['error'] ??
            'Attendance could not be marked. Response: $response',
      );
    } catch (e) {
      var msg = e.toString().replaceAll('Exception: ', '');
      if (msg.toLowerCase().contains('identity verification failed')) {
        msg = 'Face detection mismatch/issue. Please use the correct face.';
      }

      if (type == 'start' &&
          msg.toLowerCase().contains('already') &&
          msg.toLowerCase().contains('submitted')) {
        startAttendance.value = true;
        await _saveAttendanceState('start');
        await loadWorkerStatistics();
        Get.snackbar(
          'Already Submitted',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return true;
      }

      errorMessage.value = msg;
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      if (type == 'start') isStartLoading.value = false;
      if (type == 'mid') isMidLoading.value = false;
      if (type == 'end') isEndLoading.value = false;
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    await Future.wait([_fetchProfileFromApi(), loadWorkerStatistics()]);
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProfile);
      await prefs.remove(_kProfileTs);
      await prefs.remove(_kStats);
    } catch (_) {}
    workerProfile.value = null;
    currentUser.value = null;
  }

  void clearError() => errorMessage.value = '';
}
