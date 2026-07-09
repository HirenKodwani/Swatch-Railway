import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/frequency_model.dart';
import '../services/api_services.dart';

class FrequencyRepository {
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

  static Future<List<Frequency>> getAll() async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.get(
      Uri.parse('$baseUrl/api/frequencies'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = await _handleResponse(response);
    return (data['frequencies'] as List?)?.map((e) => Frequency.fromJson(e)).toList() ?? [];
  }

  static Future<Frequency> getById(String uid) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.get(
      Uri.parse('$baseUrl/api/frequencies/$uid'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = await _handleResponse(response);
    return Frequency.fromJson(data);
  }

  static Future<void> create(Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.post(
      Uri.parse('$baseUrl/api/frequencies'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    await _handleResponse(response);
  }

  static Future<void> update(String uid, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.put(
      Uri.parse('$baseUrl/api/frequencies/$uid'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    await _handleResponse(response);
  }

  static Future<void> delete(String uid) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.delete(
      Uri.parse('$baseUrl/api/frequencies/$uid'),
      headers: {'Authorization': 'Bearer $token'},
    );
    await _handleResponse(response);
  }
}
