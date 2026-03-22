import 'dart:convert';

import '../models/api_exception.dart';
import '../models/vehicle_type.dart';
import '../models/vehicle_make.dart';
import '../models/vehicle_model.dart';
import 'api_client.dart';

class VehicleService {
  static Future<List<VehicleType>> getActiveVehicleTypes() async {
    try {
      final response = await ApiClient.get(
        '/vehicle-type/get-vehicle-type/status/ACTIVE',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load vehicle types');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Invalid vehicle type response');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(VehicleType.fromJson)
          .toList();
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  static Future<List<VehicleMake>> getVehicleMakesByStatus(String status) async {
    try {
      final response = await ApiClient.get(
        '/vehicle-make/get-vehicle-make/status/$status',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load vehicle makes');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Invalid vehicle make response');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(VehicleMake.fromJson)
          .toList();
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  static Future<List<VehicleModel>> getVehicleModelsByMakeId(
    int vehicleMakeId, {
    String status = 'ACTIVE',
  }) async {
    try {
      final response = await ApiClient.get(
        '/vehicle-model/get-vehicle-models/vehicle-make-id/$vehicleMakeId/status/$status',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load vehicle models');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Invalid vehicle model response');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(VehicleModel.fromJson)
          .toList();
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /driver-profile/{driverProfileId}/vehicles
  /// Fetches all vehicles for a driver profile
  static Future<Map<String, dynamic>> getDriverVehicles(int driverProfileId) async {
    try {
      final response = await ApiClient.get(
        '/driver-profile/$driverProfileId/vehicles',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        if (error.containsKey('errorMessage') && error['errorMessage'] != null) {
          throw ApiException(error['errorMessage']);
        }
        throw Exception(error['message'] ?? 'Failed to fetch vehicles');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// PUT /driver-profile/vehicles/{vehicleId}
  /// Updates a specific vehicle
  static Future<void> updateVehicle({
    required int vehicleId,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await ApiClient.put(
        '/driver-profile/vehicle/$vehicleId',
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final error = jsonDecode(response.body);
      if (error.containsKey('errorMessage') && error['errorMessage'] != null) {
        throw ApiException(error['errorMessage']);
      }
      throw Exception(error['message'] ?? 'Failed to update vehicle');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}