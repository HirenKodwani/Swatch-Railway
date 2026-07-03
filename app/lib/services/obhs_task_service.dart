import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/api_error_handler.dart';
import '../model/task_header_model.dart';
import '../model/task_detail_model.dart';
import '../services/api_services.dart';

class OBHSTaskService {
  static String get baseUrl => ApiService.baseUrl;

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

  static Future<List<TaskHeaderModel>> getTaskHeaders(String runInstanceId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final uri = Uri.parse('$baseUrl/api/obhs/tasks/headers').replace(
        queryParameters: {'runInstanceId': runInstanceId},
      );

      final response = await _handleRequest(
        () => http.get(uri, headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final headers = (data['headers'] as List<dynamic>?)
                ?.map((h) => TaskHeaderModel.fromJson(h as Map<String, dynamic>))
                .toList() ??
            [];
        return headers;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  static Future<List<TaskDetailModel>> getTaskDetails(String headerId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/api/obhs/tasks/details/$headerId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final details = (data['details'] as List<dynamic>?)
                ?.map((d) => TaskDetailModel.fromJson(d as Map<String, dynamic>))
                .toList() ??
            [];
        return details;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  static Future<List<TaskDetailModel>> getCoachTasks(String runInstanceId, String coachNo) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final uri = Uri.parse('$baseUrl/api/obhs/tasks/coach').replace(
        queryParameters: {
          'runInstanceId': runInstanceId,
          'coachNo': coachNo,
        },
      );

      final response = await _handleRequest(
        () => http.get(uri, headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tasks = (data['tasks'] as List<dynamic>?)
                ?.map((t) => TaskDetailModel.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [];
        return tasks;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  static Future<bool> submitTaskDetail(TaskDetailModel task, {required String beforePhotoPath, required String afterPhotoPath}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/api/obhs/tasks/submit'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            ...task.toJson(),
            'beforePhoto': beforePhotoPath,
            'afterPhoto': afterPhotoPath,
            'deviceTimestamp': DateTime.now().toUtc().toIso8601String(),
          }),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  static Future<bool> updateTaskDetailStatus(String detailId, String status, {String? remarks}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final body = <String, dynamic>{
        'status': status,
      };
      if (remarks != null && remarks.isNotEmpty) {
        body['remarks'] = remarks;
      }

      final response = await _handleRequest(
        () => http.patch(
          Uri.parse('$baseUrl/api/obhs/tasks/detail/$detailId/status'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }
}
