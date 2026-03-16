import 'dart:convert';
import '../models/api_response.dart';
import '../models/api_exception.dart';
import '../models/user_profile.dart';
import 'api_client.dart';

/// Handles all user-related API calls (authenticated — token auto-attached).
class UserService {
  /// GET /user-profile/user/{userId} — fetch full user profile by userId.
  static Future<UserProfile> getUserProfileByUserId(String userId) async {
    try {
      final response = await ApiClient.get('/user-profile/user/$userId');

      if (response.statusCode == 200) {
        return UserProfile.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        if (error.containsKey('errorMessage') && error['errorMessage'] != null) {
          throw ApiException(error['errorMessage']);
        }
        throw Exception(error['message'] ?? 'Failed to fetch user profile');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

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

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.put('/user/profile', body: data);

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonDecode(response.body)) as Map<String, dynamic>;
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

  /// POST /user-profile/create — create the user profile with personal & ID details.
  static Future<Map<String, dynamic>> createUserProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post('/user-profile/create', body: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        if (error.containsKey('errorMessage') && error['errorMessage'] != null) {
          throw ApiException(error['errorMessage']);
        }
        throw Exception(error['message'] ?? 'Failed to create user profile');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}
