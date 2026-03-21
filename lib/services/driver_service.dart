import 'dart:convert';
import '../models/driver_profile.dart';
import '../models/driver_vehicles_response.dart';
import '../models/api_exception.dart';
import 'api_client.dart';
import 'token_service.dart';

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

  /// GET /driver-profile/{driverProfileId}/vehicles
  static Future<DriverVehiclesResponse> getDriverVehicles(int driverProfileId) async {
    try {
      final response = await ApiClient.get('/driver-profile/$driverProfileId/vehicles');
      if (response.statusCode == 200) {
        return DriverVehiclesResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch vehicles');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// POST /driver-profile/save/{userId}
  static Future<void> saveDriverProfile({
    required Map<String, dynamic> body,
  }) async {
    try {
      final userId = await TokenService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await ApiClient.post(
        '/driver-profile/save/$userId',
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final error = jsonDecode(response.body);
      if (error.containsKey('errorMessage') && error['errorMessage'] != null) {
        throw ApiException(error['errorMessage']);
      }
      throw Exception(error['message'] ?? 'Failed to save driver profile');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}
