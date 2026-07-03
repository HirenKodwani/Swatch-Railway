import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/material_model.dart';
import '../services/api_services.dart';

class MaterialRepository {
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

  static Future<List<MaterialItem>> getAll({String? stationId}) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    var url = '$baseUrl/api/materials';
    if (stationId != null) url += '?stationId=$stationId';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = await _handleResponse(response);
    return (data['materials'] as List?)?.map((e) => MaterialItem.fromJson(e)).toList() ?? [];
  }

  static Future<MaterialItem> getById(String uid) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.get(
      Uri.parse('$baseUrl/api/materials/$uid'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = await _handleResponse(response);
    return MaterialItem.fromJson(data);
  }

  static Future<void> create(Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.post(
      Uri.parse('$baseUrl/api/materials'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    await _handleResponse(response);
  }

  static Future<void> update(String uid, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.put(
      Uri.parse('$baseUrl/api/materials/$uid'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    await _handleResponse(response);
  }

  static Future<void> delete(String uid) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.delete(
      Uri.parse('$baseUrl/api/materials/$uid'),
      headers: {'Authorization': 'Bearer $token'},
    );
    await _handleResponse(response);
  }

  static Future<void> issue(String uid, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.post(
      Uri.parse('$baseUrl/api/materials/$uid/issue'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    await _handleResponse(response);
  }

  static Future<void> receive(String uid, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    final response = await http.post(
      Uri.parse('$baseUrl/api/materials/$uid/receive'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    await _handleResponse(response);
  }

  static Future<List<StockAlert>> getAlerts({String? stationId}) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    var url = '$baseUrl/api/materials/alerts';
    if (stationId != null) url += '?stationId=$stationId';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = await _handleResponse(response);
    return (data['alerts'] as List?)?.map((e) => StockAlert.fromJson(e)).toList() ?? [];
  }

  static Future<List<MaterialTransaction>> getLogs({String? materialId, String? stationId}) async {
    final token = await _getToken();
    if (token == null) throw Exception('AUTH_ERROR');
    var url = '$baseUrl/api/materials/logs?';
    if (materialId != null) url += 'materialId=$materialId&';
    if (stationId != null) url += 'stationId=$stationId';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = await _handleResponse(response);
    return (data['transactions'] as List?)?.map((e) => MaterialTransaction.fromJson(e)).toList() ?? [];
  }
}
