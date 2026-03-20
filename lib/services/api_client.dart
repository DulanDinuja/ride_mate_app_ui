import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import 'token_service.dart';

/// Base HTTP client used by all service classes.
///
/// • [get], [post], [put], [patch], [delete] — authenticated requests.
///   The stored JWT token is attached automatically.
///   On a 401 response the token is refreshed once and the request retried.
///
/// • [publicPost] — unauthenticated request (no token attached).
class ApiClient {
  /// Base URL is resolved from [AppConfig] which reads `--dart-define` values.
  ///
  /// Local  (default): `http://localhost:8080/ride-mate`
  /// Prod   (Codemagic): set via `BASE_URL` environment variable.
  static String get baseUrl => AppConfig.baseUrl;

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

  // ─── Multipart upload (authenticated, 401 auto-retry) ────────────

  /// Sends a multipart POST with one file field.
  ///
  /// On a 401 the token is refreshed once and the request is retried,
  /// exactly like [get]/[post]/[put]/[patch]/[delete].
  static Future<http.Response> multipartPost(
    String endpoint, {
    required Uint8List fileBytes,
    required String fileName,
    String fieldName = 'file',
  }) async {
    return _withTokenRefresh(() async {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      final authHeader = await TokenService.getAuthorizationHeader();
      if (authHeader != null) {
        request.headers['Authorization'] = authHeader;
      }

      request.files.add(
        http.MultipartFile.fromBytes(fieldName, fileBytes, filename: fileName),
      );

      final streamed = await request.send();
      return http.Response.fromStream(streamed);
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

  /// Guards concurrent refresh attempts so only one network call is made.
  static Completer<bool>? _refreshCompleter;

  static Future<bool> _tryRefreshToken() async {
    // If a refresh is already in progress, wait for it.
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await TokenService.getRefreshToken();
      if (refreshToken == null) {
        _refreshCompleter!.complete(false);
        return false;
      }

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
          _refreshCompleter!.complete(true);
          return true;
        }
      }

      _refreshCompleter!.complete(false);
      return false;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }
}