import 'dart:convert';
import '../models/api_response.dart';
import '../models/api_exception.dart';
import 'api_client.dart';

/// Handles all user-related API calls (authenticated — token auto-attached).
class UserService {
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiClient.get('/user/profile');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        if (error.containsKey('errorMessage') && error['errorMessage'] != null) {
          throw ApiException(error['errorMessage']);
        }
        throw Exception(error['message'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  static Future<ApiResponse> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.put('/user/profile', body: data);

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        if (error.containsKey('errorMessage') && error['errorMessage'] != null) {
          throw ApiException(error['errorMessage']);
        }
        throw Exception(error['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}
