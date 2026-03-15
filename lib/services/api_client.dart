import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart';

/// Base HTTP client used by all service classes.
///
/// • [get], [post], [put], [patch], [delete] — authenticated requests.
///   The stored JWT token is attached automatically.
///   On a 401 response the token is refreshed once and the request retried.
///
/// • [publicPost] — unauthenticated request (no token attached).
class ApiClient {
  static const String baseUrl = 'http://localhost:8080/ride-mate';
  // Android emulator  → http://10.0.2.2:8080/ride-mate
  // iOS simulator     → http://localhost:8080/ride-mate
  // Physical device   → http://YOUR_IP:8080/ride-mate

  // ─── Headers ──────────────────────────────────────────────────────

  static Map<String, String> get _publicHeaders => {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, String>> _authHeaders() async {
    final authHeader = await TokenService.getAuthorizationHeader();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authHeader != null) {
      headers['Authorization'] = authHeader;
    }
    return headers;
  }

  // ─── Public (no token) ────────────────────────────────────────────

  static Future<http.Response> publicGet(String endpoint) async {
    return await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _publicHeaders,
    );
  }

  static Future<http.Response> publicPost(
    String endpoint, {
    Object? body,
  }) async {
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _publicHeaders,
      body: body is String ? body : (body != null ? jsonEncode(body) : null),
    );
  }

  // ─── Authenticated (token auto-attached, 401 auto-retry) ─────────

  static Future<http.Response> get(String endpoint) async {
    return _withTokenRefresh(() async {
      final headers = await _authHeaders();
      return await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
    });
  }

  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _withTokenRefresh(() async {
      final headers = await _authHeaders();
      return await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _withTokenRefresh(() async {
      final headers = await _authHeaders();
      return await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  static Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _withTokenRefresh(() async {
      final headers = await _authHeaders();
      return await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  static Future<http.Response> delete(String endpoint) async {
    return _withTokenRefresh(() async {
      final headers = await _authHeaders();
      return await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
    });
  }

  // ─── 401 auto-retry logic ────────────────────────────────────────

  static Future<http.Response> _withTokenRefresh(
    Future<http.Response> Function() request,
  ) async {
    final response = await request();

    if (response.statusCode == 401) {
      // Attempt to refresh the token once
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return await request(); // retry with new token
      }
    }

    return response;
  }

  static Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await TokenService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: _publicHeaders,
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'] as String?;
        if (newAccessToken != null) {
          await TokenService.saveTokens(
            accessToken: newAccessToken,
            refreshToken: data['refreshToken'] as String?,
            tokenType: data['tokenType'] as String?,
          );
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}