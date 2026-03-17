import 'dart:convert';

import '../models/vehicle_type.dart';
import '../models/vehicle_make.dart';
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
}
