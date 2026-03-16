import 'dart:convert';
import '../models/api_exception.dart';
import '../models/api_response.dart';
import '../models/login_request.dart';
import '../models/send_verification_code_request.dart';
import '../models/user_registration_request.dart';
import '../models/verify_code_request.dart';
import 'api_client.dart';
import 'token_service.dart';

/// Handles all authentication-related API calls (public, no token needed).
class AuthService {
  // ─── Register ─────────────────────────────────────────────────────

  static Future<LoginResponse> registerUser(UserRegistrationRequest request) async {
    try {
      final response = await ApiClient.publicPost(
        '/auth/register',
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
        if (loginResponse.success && loginResponse.accessToken != null) {
          await TokenService.saveLoginResponse(loginResponse);
        }
        return loginResponse;
      } else {
        final error = jsonDecode(response.body);
        if (error.containsKey('errorMessage') && error['errorMessage'] != null) {
          throw ApiException(error['errorMessage']);
        }
        final msg = error['messages'] ?? 'Registration failed';
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ─── Login ────────────────────────────────────────────────────────

  static Future<LoginResponse> loginUser(LoginRequest request) async {
    try {
      final response = await ApiClient.publicPost(
        '/auth/login',
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));

        if (loginResponse.success && loginResponse.accessToken != null) {
          await TokenService.saveLoginResponse(loginResponse);
        }

        return loginResponse;
      } else {
        final error = jsonDecode(response.body);
        if (error.containsKey('errorMessage') && error['errorMessage'] != null) {
          throw ApiException(error['errorMessage']);
        }
        final msg = error['messages'] ?? 'Login failed';
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ─── Email verification ───────────────────────────────────────────

  static Future<ApiResponse> sendVerificationCode(SendVerificationCodeRequest request) async {
    try {
      final response = await ApiClient.publicPost(
        '/auth/send-verification-code',
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        if (error.containsKey('errorMessage') && error['errorMessage'] != null) {
          throw ApiException(error['errorMessage']);
        }
        throw Exception(error['messages'] ?? 'Failed to send verification code');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  static Future<ApiResponse> verifyCode(VerifyCodeRequest request) async {
    try {
      final response = await ApiClient.publicPost(
        '/auth/verify-code',
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        if (error.containsKey('errorMessage') && error['errorMessage'] != null) {
          throw ApiException(error['errorMessage']);
        }
        throw Exception(error['messages'] ?? 'Verification failed');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────

  static Future<void> logout() async {
    await TokenService.clearAll();
  }
}
