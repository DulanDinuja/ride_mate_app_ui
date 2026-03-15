import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart';

/// A common HTTP client that attaches JWT authorization headers
/// to every request. Use this in any service that needs authenticated calls.
class AuthHttpClient {
  static const String baseUrl = 'http://localhost:8080/ride-mate';
  // For Android emulator: http://10.0.2.2:8080/ride-mate
  // For iOS simulator: http://localhost:8080/ride-mate
  // For physical device: http://YOUR_IP:8080/ride-mate

  /// Build headers with JWT token for authenticated requests
  static Future<Map<String, String>> getAuthHeaders() async {
    final authHeader = await TokenService.getAuthorizationHeader();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authHeader != null) {
      headers['Authorization'] = authHeader;
    }
    return headers;
  }

  /// Authenticated GET request
  static Future<http.Response> get(String endpoint) async {
    final headers = await getAuthHeaders();
    return await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
  }

  /// Authenticated POST request
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await getAuthHeaders();
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// Authenticated PUT request
  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await getAuthHeaders();
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// Authenticated DELETE request
  static Future<http.Response> delete(String endpoint) async {
    final headers = await getAuthHeaders();
    return await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
  }

  /// Authenticated PATCH request
  static Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await getAuthHeaders();
    return await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }
}

