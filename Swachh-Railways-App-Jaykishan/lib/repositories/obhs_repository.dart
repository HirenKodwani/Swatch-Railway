import 'dart:async';
import 'dart:convert';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/services/firebase_obhs_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/api_error_handler.dart';
import '../model/run_instance_model.dart';
import '../model/railway_worker_model.dart';
import '../model/train_model.dart';

class JourneyAdvanceResult {
  final bool success;
  final String message;
  final String? runInstanceId;
  final String? previousState;
  final String? currentState;

  JourneyAdvanceResult({
    required this.success,
    required this.message,
    this.runInstanceId,
    this.previousState,
    this.currentState,
  });

  factory JourneyAdvanceResult.fromJson(Map<String, dynamic> json) {
    return JourneyAdvanceResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      runInstanceId: json['runInstanceId'] as String?,
      previousState: json['previousState'] as String?,
      currentState: json['currentState'] as String?,
    );
  }
}

class JourneyTimelineResult {
  final bool success;
  final String? runInstanceId;
  final List<JourneyTimelineEntry> timeline;
  final Map<String, dynamic>? metrics;

  JourneyTimelineResult({
    required this.success,
    this.runInstanceId,
    this.timeline = const [],
    this.metrics,
  });

  factory JourneyTimelineResult.fromJson(Map<String, dynamic> json) {
    return JourneyTimelineResult(
      success: json['success'] as bool? ?? false,
      runInstanceId: json['runInstanceId'] as String?,
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => JourneyTimelineEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metrics: json['metrics'] as Map<String, dynamic>?,
    );
  }
}

class OBHSRepository {

  static const String baseUrl = ApiService.baseUrl;

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<http.Response> _handleRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }


  static Future<List<TrainModel>> getOBHSTrains() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/api/trains?applicableFor=OBHS&status=active'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final trains = (data['trains'] as List<dynamic>?)
                ?.map((train) => TrainModel.fromJson(train as Map<String, dynamic>))
                .toList() ??
            [];
        return trains;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(
          response.body,
          response.statusCode,
        ));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }


  static Future<List<RunInstanceModel>> getRunInstancesByTrain(
      String trainId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/api/train-pairs/train/$trainId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final instances = (data['data'] as List<dynamic>?)
                ?.map((instance) =>
                    RunInstanceModel.fromJson(instance as Map<String, dynamic>))
                .toList() ??
            [];
        return instances;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(
          response.body,
          response.statusCode,
        ));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }


  static Future<List<RailwayWorkerModel>> getRailwayWorkers() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/api/admin/railway-workers'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final workers = (data['workers'] as List<dynamic>?)
                ?.map((worker) =>
                    RailwayWorkerModel.fromJson(worker as Map<String, dynamic>))
                .toList() ??
            [];
        return workers;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(
          response.body,
          response.statusCode,
        ));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }


  static Future<RunInstanceModel> createRunInstance({
    required String instanceId,
    required List<CoachAssignment> coaches,
    required DateTime departureDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final requestBody = {
        'instanceId': instanceId,
        'coaches': coaches.map((coach) => coach.toJson()).toList(),
        'departureDate': '${departureDate.year}-'
            '${departureDate.month.toString().padLeft(2, '0')}-'
            '${departureDate.day.toString().padLeft(2, '0')}',
      };

      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/api/run-instances'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestBody),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Assuming the response contains the created instance in 'data' field
        final instanceData = data['data'] ?? data;
        final created = RunInstanceModel.fromJson(instanceData as Map<String, dynamic>);

        // ── Mirror to Firestore so reports can query it ──────────────────────
        unawaited(FirebaseOBHSService.saveRunInstance({
          'runInstanceId': created.runInstanceId ?? created.instanceId,
          'instanceId': created.instanceId,
          'trainNo': created.trainNo,
          'trainName': created.trainName,
          'inboundTrainNo': created.inboundTrainNo,
          'outboundTrainNo': created.outboundTrainNo,
          'departureDate': created.departureDate != null
              ? '${created.departureDate!.year}-'
                '${created.departureDate!.month.toString().padLeft(2, '0')}-'
                '${created.departureDate!.day.toString().padLeft(2, '0')}'
              : null,
          'status': created.status,
          'coaches': created.coaches.map((c) => c.toJson()).toList(),
          'createdBy': created.createdBy,
          'createdByName': created.createdByName,
        }));
        return created;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(
          response.body,
          response.statusCode,
        ));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }


  static Future<RunInstanceModel> updateRunInstance({
    required String runInstanceId,
    String? status,
    List<CoachAssignment>? coaches,
    DateTime? departureDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final requestBody = <String, dynamic>{};
      if (status != null) {
        requestBody['status'] = status;
      }
      if (coaches != null && coaches.isNotEmpty) {
        requestBody['coaches'] = coaches.map((coach) => coach.toJson()).toList();
      }
      if (departureDate != null) {
        requestBody['departureDate'] = '${departureDate.year}-'
            '${departureDate.month.toString().padLeft(2, '0')}-'
            '${departureDate.day.toString().padLeft(2, '0')}'; 
      }

      final response = await _handleRequest(
        () => http.put(
          Uri.parse('$baseUrl/api/run-instances/$runInstanceId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestBody),
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final instanceData = data['data'] ?? data;
        return RunInstanceModel.fromJson(instanceData as Map<String, dynamic>);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(
          response.body,
          response.statusCode,
        ));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  /// Delete Run Instance
  /// [runInstanceId] - The run instance ID to delete
  /// Returns success message
  static Future<Map<String, dynamic>> deleteRunInstance(
      String runInstanceId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final response = await _handleRequest(
        () => http.delete(
          Uri.parse('$baseUrl/api/run-instances/$runInstanceId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else {
          return {'message': 'Run instance deleted successfully'};
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(
          response.body,
          response.statusCode,
        ));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  /// Get OBHS Attendance List (admin view)
  static Future<List<Map<String, dynamic>>> getAttendanceList({String? runInstanceId}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('AUTH_ERROR');
      final params = <String, String>{};
      if (runInstanceId != null) params['runInstanceId'] = runInstanceId;
      final uri = Uri.parse('$baseUrl/api/obhs/attendance/list').replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await _handleRequest(
        () => http.get(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['records'] ?? []);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) rethrow;
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  /// Get All Run Instances (for list screen)
  /// Returns all run instances across all trains
  static Future<List<RunInstanceModel>> getAllRunInstances() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/api/run-instances'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final instances = (data['data'] as List<dynamic>?)
                ?.map((instance) =>
                    RunInstanceModel.fromJson(instance as Map<String, dynamic>))
                .toList() ??
            [];
        return instances;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(
          response.body,
          response.statusCode,
        ));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  // --- Supervisor / Contractor APIs ---

  static Future<List<RailwayWorkerModel>> getWorkers() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('AUTH_ERROR');

      final response = await _handleRequest(() => http.get(
        Uri.parse('$baseUrl/api/users/workers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final workersData = data['workers'] as List<dynamic>? ?? [];
        return workersData.map((w) => RailwayWorkerModel.fromJson(w as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) rethrow;
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  static Future<List<dynamic>> getPendingReviewTasks(String runInstanceId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('AUTH_ERROR');

      final response = await _handleRequest(() => http.get(
        Uri.parse('$baseUrl/api/tasks/pending-review?runInstanceId=$runInstanceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['data'] as List<dynamic>? ?? [];
      } else if (response.statusCode == 401) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) rethrow;
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  // ─── JOURNEY LIFECYCLE METHODS ────────────────────────────────────────

  static Future<JourneyAdvanceResult> advanceJourney(
    String runInstanceId, {
    String? toState,
    String? actualDeparture,
    String? actualArrival,
    int? delayMinutes,
    String? remarks,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('AUTH_ERROR');

      final body = <String, dynamic>{};
      if (toState != null) body['toState'] = toState;
      if (actualDeparture != null) body['actualDeparture'] = actualDeparture;
      if (actualArrival != null) body['actualArrival'] = actualArrival;
      if (delayMinutes != null) body['delayMinutes'] = delayMinutes;
      if (remarks != null) body['remarks'] = remarks;

      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/api/v2/journey/$runInstanceId/advance'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return JourneyAdvanceResult.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) rethrow;
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  static Future<JourneyTimelineResult> getJourneyTimeline(String runInstanceId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('AUTH_ERROR');

      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/api/v2/journey/$runInstanceId/timeline'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return JourneyTimelineResult.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) rethrow;
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  static Future<List<RunInstanceModel>> getJourneys({
    String? status,
    String? trainNo,
    String? date,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('AUTH_ERROR');

      final params = <String, String>{};
      if (status != null) params['status'] = status;
      if (trainNo != null) params['trainNo'] = trainNo;
      if (date != null) params['date'] = date;
      final queryString = params.isNotEmpty ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}' : '';

      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/api/v2/journeys$queryString'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final journeys = (data['journeys'] as List<dynamic>?)
                ?.map((j) => RunInstanceModel.fromJson(j as Map<String, dynamic>))
                .toList() ??
            [];
        return journeys;
      } else if (response.statusCode == 401) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) rethrow;
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  static Future<void> updateTaskStatus(String taskId, String status, {int? passengerScore, int? supervisorScore}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('AUTH_ERROR');

      final body = <String, dynamic>{'status': status};
      if (passengerScore != null) body['passengerScore'] = passengerScore;
      if (supervisorScore != null) body['supervisorScore'] = supervisorScore;

      final url = status.toLowerCase() == 'approved' 
        ? '$baseUrl/api/tasks/$taskId/approve'
        : '$baseUrl/api/tasks/$taskId/reject';

      final response = await _handleRequest(() => http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) rethrow;
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }
}
