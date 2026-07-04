import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_services.dart';
import '../model/station_cleaning_models.dart';

class InspectionRepository {
  static String get baseUrl => ApiService.baseUrl;
  static Future<Map<String, String>> _headers() async {
    final token = await ApiService.getToken();
    return {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};
  }

  static Future<List<StationInspection>> list(Map<String, String> query) async {
    final uri = Uri.parse('$baseUrl/api/inspections').replace(queryParameters: query);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body)['inspections'] ?? [];
      return list.map((e) => StationInspection.fromJson(e)).toList();
    }
    throw Exception('Failed to load inspections');
  }

  static Future<StationInspection> getById(String uid) async {
    final res = await http.get(Uri.parse('$baseUrl/api/inspections/$uid'), headers: await _headers());
    if (res.statusCode == 200) return StationInspection.fromJson(jsonDecode(res.body));
    throw Exception('Failed to load inspection');
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('$baseUrl/api/inspections'), headers: await _headers(), body: jsonEncode(data));
    if (res.statusCode == 201 || res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to create inspection');
  }

  static Future<void> start(String uid) async {
    final res = await http.post(Uri.parse('$baseUrl/api/inspections/$uid/start'), headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to start inspection');
  }

  static Future<void> submitRatings(String uid, Map<String, dynamic> ratings) async {
    final res = await http.post(Uri.parse('$baseUrl/api/inspections/$uid/ratings'), headers: await _headers(), body: jsonEncode(ratings));
    if (res.statusCode != 200) throw Exception('Failed to submit ratings');
  }

  static Future<void> addDeficiency(String uid, Map<String, dynamic> def) async {
    final res = await http.post(Uri.parse('$baseUrl/api/inspections/$uid/deficiencies'), headers: await _headers(), body: jsonEncode(def));
    if (res.statusCode != 200) throw Exception('Failed to add deficiency');
  }

  static Future<void> closeDeficiency(String uid, String defId, String proofUrl) async {
    final res = await http.post(Uri.parse('$baseUrl/api/inspections/$uid/deficiencies/$defId/close'), headers: await _headers(), body: jsonEncode({'closureProof': proofUrl}));
    if (res.statusCode != 200) throw Exception('Failed to close deficiency');
  }

  static Future<List<Map<String, dynamic>>> listTemplates() async {
    final res = await http.get(Uri.parse('$baseUrl/api/inspections/templates'), headers: await _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body)['templates'] ?? [];
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load templates');
  }

  static Future<void> createTemplate(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('$baseUrl/api/inspections/templates'), headers: await _headers(), body: jsonEncode(data));
    if (res.statusCode != 201 && res.statusCode != 200) throw Exception('Failed to create template');
  }
}
