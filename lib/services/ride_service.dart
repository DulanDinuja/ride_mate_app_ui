import 'dart:convert';

import '../models/api_exception.dart';
import '../models/cost_split_response.dart';
import '../models/passenger_ride_confirm_request.dart';
import '../models/ride_detail_request.dart';
import '../models/ride_price_calculation_response.dart';
import 'api_client.dart';

/// Handles all ride-related API calls (authenticated — token auto-attached).
class RideService {
  /// POST /ride-details/confirm — confirm a passenger joining a ride.
  /// Returns the full cost-split breakdown after the passenger is added.
  static Future<CostSplitResponse> confirmPassengerRide(
    PassengerRideConfirmRequest request,
  ) async {
    try {
      final response = await ApiClient.post(
        '/ride-details/confirm',
        body: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return CostSplitResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['errorMessage'];
          if (msg != null) {
            throw ApiException(msg.toString());
          }
        }
        throw Exception('Failed to confirm ride');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /ride-details/calculate-price — calculate ride price based on driver profile and distance.
  static Future<RidePriceCalculationResponse> calculateRidePrice({
    required int driverProfileId,
    required double totalDistance,
  }) async {
    try {
      final response = await ApiClient.get(
        '/ride-details/calculate-price'
        '?driverProfileId=$driverProfileId'
        '&totalDistance=$totalDistance',
      );

      if (response.statusCode == 200) {
        return RidePriceCalculationResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['errorMessage'];
          if (msg != null) {
            throw ApiException(msg.toString());
          }
        }
        throw Exception('Failed to calculate ride price');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// POST /ride-details/addRide — create a new ride detail (driver starts a ride).
  static Future<Map<String, dynamic>> createRideDetail(
    RideDetailRequest request,
  ) async {
    try {
      final response = await ApiClient.post(
        '/ride-details/addRide',
        body: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['errorMessage'];
          if (msg != null) {
            throw ApiException(msg.toString());
          }
        }
        throw Exception('Failed to create ride');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /ride-details/{rideDetailId}/cost-split — get cost split breakdown.
  static Future<CostSplitResponse> getCostSplit(int rideDetailId) async {
    try {
      final response = await ApiClient.get(
        '/ride-details/$rideDetailId/cost-split',
      );

      if (response.statusCode == 200) {
        return CostSplitResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['errorMessage'];
          if (msg != null) {
            throw ApiException(msg.toString());
          }
        }
        throw Exception('Failed to get cost split');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// POST /ride-details/{rideDetailId}/cost-split/recalculate — recalculate cost split.
  static Future<CostSplitResponse> recalculateCostSplit(
      int rideDetailId) async {
    try {
      final response = await ApiClient.post(
        '/ride-details/$rideDetailId/cost-split/recalculate',
      );

      if (response.statusCode == 200) {
        return CostSplitResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['errorMessage'];
          if (msg != null) {
            throw ApiException(msg.toString());
          }
        }
        throw Exception('Failed to recalculate cost split');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}

