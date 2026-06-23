import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_services.dart';

class PassengerService {
  static const String baseUrl = ApiService.baseUrl;

  static Future<Map<String, dynamic>> createCleaningTask({
    required String trainNo,
    required String coachNo,
    required String seatNo,
    required String taskType,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/passenger/create-task'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'trainNo': trainNo,
          'coachNo': coachNo,
          'seatNo': seatNo,
          'taskType': taskType,
          'description': description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to create task');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  static Future<List<String>> fetchCoachesForTrain(String trainNo) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/passenger/train/$trainNo/coaches'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['coaches'] != null) {
          return List<String>.from(data['coaches']);
        }
        return [];
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to fetch coaches');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
