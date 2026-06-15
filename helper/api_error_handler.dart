import 'dart:convert';

class ApiErrorHandler {
  static String getErrorMessage(dynamic error, int? statusCode) {
    final serverMessage = _extractServerMessage(error);
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return serverMessage;
    }

    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      return 'No internet connection. Please check your network.';
    }

    if (error.toString().contains('TimeoutException')) {
      return 'Request timeout. Please try again.';
    }

    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied. You don\'t have permission.';
      case 404:
        return 'Data not found.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
      case 503:
        return 'Service temporarily unavailable.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static bool isAuthError(int? statusCode) {
    return statusCode == 401 || statusCode == 403;
  }

  static String? _extractServerMessage(dynamic error) {
    var raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      raw = raw.substring('Exception: '.length).trim();
    }

    if (raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'error', 'detail']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }

        final errors = decoded['errors'];
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first;
          if (first is String && first.trim().isNotEmpty) {
            return first.trim();
          }
          if (first is Map<String, dynamic>) {
            final message = first['message'] ?? first['msg'];
            if (message is String && message.trim().isNotEmpty) {
              return message.trim();
            }
          }
        }
      }
    } catch (_) {
      if (!raw.startsWith('{') && !raw.startsWith('[')) {
        return raw;
      }
    }

    return null;
  }
}
