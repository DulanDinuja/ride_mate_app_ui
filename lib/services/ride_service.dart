import 'dart:convert';
import 'dart:developer' as dev;

import '../models/api_exception.dart';
import '../models/cost_split_response.dart';
import '../models/passenger_ride_confirm_request.dart';
import '../models/ride_detail_request.dart';
import '../models/ride_price_calculation_response.dart';
import '../models/user_profile.dart';
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
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        dev.log('[RideService] calculateRidePrice raw: $decoded', name: 'RideService');
        return RidePriceCalculationResponse.fromJson(decoded);
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

  /// GET /ride-details/{rideDetailId}/pending-requests — get pending passenger requests.
  static Future<List<Map<String, dynamic>>> getPendingRequests(
      int rideDetailId) async {
    try {
      final response = await ApiClient.get(
        '/ride-details/$rideDetailId/pending-requests',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['errorMessage'];
          if (msg != null) {
            throw ApiException(msg.toString());
          }
        }
        throw Exception('Failed to get pending requests');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// PUT /ride-details/share/{shareRideDetailId}/accept — accept a passenger request.
  static Future<void> acceptPassengerRequest(int shareRideDetailId) async {
    try {
      final response = await ApiClient.put(
        '/ride-details/share/$shareRideDetailId/accept',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) return;

      final error = jsonDecode(response.body);
      if (error is Map) {
        final msg = error['message'] ?? error['errorMessage'];
        if (msg != null) {
          throw ApiException(msg.toString());
        }
      }
      throw Exception('Failed to accept request');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// PUT /ride-details/share/{shareRideDetailId}/reject — reject a passenger request.
  static Future<void> rejectPassengerRequest(int shareRideDetailId) async {
    try {
      final response = await ApiClient.put(
        '/ride-details/share/$shareRideDetailId/reject',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) return;

      final error = jsonDecode(response.body);
      if (error is Map) {
        final msg = error['message'] ?? error['errorMessage'];
        if (msg != null) {
          throw ApiException(msg.toString());
        }
      }
      throw Exception('Failed to reject request');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /user-profile/user/{userId} — fetch user profile for a passenger.
  static Future<UserProfile> getPassengerProfile(int userId) async {
    try {
      final response = await ApiClient.get(
        '/user-profile/user/$userId',
      );

      if (response.statusCode == 200) {
        return UserProfile.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to fetch passenger profile');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// PUT /ride-details/{rideDetailId}/end — end an active ride.
  static Future<void> endRide(int rideDetailId) async {
    try {
      final response = await ApiClient.put(
        '/ride-details/$rideDetailId/end',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) return;

      final error = jsonDecode(response.body);
      if (error is Map) {
        final msg = error['message'] ?? error['errorMessage'];
        if (msg != null) {
          throw ApiException(msg.toString());
        }
      }
      throw Exception('Failed to end ride');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /ride-details/driver/{driverProfileId}/active — get the active ride for a driver.
  static Future<Map<String, dynamic>?> getDriverActiveRide(
      int driverProfileId) async {
    try {
      final response = await ApiClient.get(
        '/ride-details/driver/$driverProfileId/active',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return null;
      } else if (response.statusCode == 404) {
        return null; // No active ride
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// GET /ride-details/driver/{driverProfileId}?status={status}
  /// Fetches rides for a driver filtered by status.
  static Future<List<Map<String, dynamic>>> getDriverRidesByStatus(
      int driverProfileId, String status) async {
    try {
      final response = await ApiClient.get(
        '/ride-details/driver/$driverProfileId?status=$status',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
        // If single object returned, wrap in list
        if (decoded is Map<String, dynamic>) {
          return [decoded];
        }
        return [];
      } else if (response.statusCode == 404) {
        return [];
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  /// PUT /ride-details/{rideDetailId}/cancel — cancel an active ride.
  static Future<void> cancelRide(int rideDetailId) async {
    try {
      final response = await ApiClient.put(
        '/ride-details/$rideDetailId/cancel',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) return;

      final error = jsonDecode(response.body);
      if (error is Map) {
        final msg = error['message'] ?? error['errorMessage'];
        if (msg != null) {
          throw ApiException(msg.toString());
        }
      }
      throw Exception('Failed to cancel ride');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}
