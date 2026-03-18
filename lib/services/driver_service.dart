import 'dart:convert';
import '../models/driver_profile.dart';
import '../models/api_exception.dart';
import 'api_client.dart';

class DriverService {
  /// GET /driver-profile/get-driver-profile/user/{userId}
  static Future<DriverProfile> getDriverProfileByUserId(String userId) async {
    try {
      final response = await ApiClient.get(
        '/driver-profile/get-driver-profile/user/$userId',
      );

      if (response.statusCode == 200) {
        return DriverProfile.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        final error = jsonDecode(response.body);
        if (error.containsKey('errorMessage') && error['errorMessage'] != null) {
          throw ApiException(error['errorMessage']);
        }
        throw Exception(error['message'] ?? 'Failed to fetch driver profile');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}
