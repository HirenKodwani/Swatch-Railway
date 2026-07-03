import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/activity_model.dart';
import '../services/api_services.dart';

class ActivityRepository {
  static String get baseUrl => ApiService.baseUrl;

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('AUTH_ERROR');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<Activity>> getAll() async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.get(
      Uri.parse('$baseUrl/api/activities'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = await _handleResponse(response);
    return (data['activities'] as List?)?.map((e) => Activity.fromJson(e)).toList() ?? [];
  }

  static Future<Activity> getById(String uid) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.get(
      Uri.parse('$baseUrl/api/activities/$uid'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = await _handleResponse(response);
    return Activity.fromJson(data);
  }

  static Future<void> create(Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.post(
      Uri.parse('$baseUrl/api/activities'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    await _handleResponse(response);
  }

  static Future<void> update(String uid, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.put(
      Uri.parse('$baseUrl/api/activities/$uid'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    await _handleResponse(response);
  }

  static Future<void> delete(String uid) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.delete(
      Uri.parse('$baseUrl/api/activities/$uid'),
      headers: {'Authorization': 'Bearer $token'},
    );
    await _handleResponse(response);
  }
}
