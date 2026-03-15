import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/api_response.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();

  // Storage keys
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenTypeKey = 'token_type';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _emailKey = 'email';
  static const _roleKey = 'role';

  /// Save all tokens and user info from login response
  static Future<void> saveLoginResponse(LoginResponse response) async {
    if (response.accessToken != null) {
      await _storage.write(key: _accessTokenKey, value: response.accessToken);
    }
    if (response.refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: response.refreshToken);
    }
    if (response.tokenType != null) {
      await _storage.write(key: _tokenTypeKey, value: response.tokenType);
    }
    if (response.userId != null) {
      await _storage.write(key: _userIdKey, value: response.userId.toString());
    }
    if (response.userName != null) {
      await _storage.write(key: _userNameKey, value: response.userName);
    }
    if (response.email != null) {
      await _storage.write(key: _emailKey, value: response.email);
    }
    if (response.role != null) {
      await _storage.write(key: _roleKey, value: response.role);
    }
  }

  /// Get the access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get the refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Get the Authorization header value (e.g. "Bearer <token>")
  static Future<String?> getAuthorizationHeader() async {
    final token = await getAccessToken();
    final tokenType = await _storage.read(key: _tokenTypeKey) ?? 'Bearer';
    if (token != null) {
      return '$tokenType $token';
    }
    return null;
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Get stored user name
  static Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  /// Get stored email
  static Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  /// Get stored role
  static Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  /// Check if user is logged in (has a token)
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  /// Clear all stored tokens and user info (logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

