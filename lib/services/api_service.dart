import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_registration_request.dart';
import '../models/login_request.dart';
import '../models/api_response.dart';
import '../models/send_verification_code_request.dart';
import '../models/verify_code_request.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/ride-mate';
  // For Android emulator: http://10.0.2.2:8080/ride-mate
  // For iOS simulator: http://localhost:8080/ride-mate
  // For physical device: http://YOUR_IP:8080/ride-mate

  static Future<ApiResponse> registerUser(UserRegistrationRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user-registration'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        return ApiResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['messages'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<LoginResponse> loginUser(LoginRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/with-email-and-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['messages'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<ApiResponse> sendVerificationCode(SendVerificationCodeRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-verification-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['messages'] ?? 'Failed to send verification code');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<ApiResponse> verifyCode(VerifyCodeRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['messages'] ?? 'Verification failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
