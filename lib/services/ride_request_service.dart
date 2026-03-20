import 'dart:convert';
import 'dart:developer' as dev;

import '../models/api_exception.dart';
import '../models/available_ride.dart';
import '../models/ride_request.dart';
import 'api_client.dart';

/// Handles all ride-request-related API calls (authenticated).
class RideRequestService {
  /// GET /ride-requests/available-rides — get available rides near the
  /// passenger's destination.
  static Future<List<AvailableRide>> getAvailableRides({
    double? endLat,
    double? endLng,
    double? radiusKm,
  }) async {
    try {
      final params = <String>[];
      if (endLat != null) params.add('endLat=$endLat');
      if (endLng != null) params.add('endLng=$endLng');
      if (radiusKm != null) params.add('radiusKm=$radiusKm');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';

      final response = await ApiClient.get('/ride-requests/available-rides$query');

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) => AvailableRide.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _throwApiError(response.body, 'Failed to fetch available rides');
        return []; // unreachable
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// POST /ride-requests — create a ride request (passenger requests to join).
  static Future<RideRequest> createRideRequest({
    required int rideDetailId,
    required int userId,
    required double passengerStartLat,
    required double passengerStartLng,
    required double passengerEndLat,
    required double passengerEndLng,
    required double passengerRideDistance,
    String? startCity,
    String? endCity,
  }) async {
    try {
      final body = {
        'rideDetailId': rideDetailId,
        'userId': userId,
        'passengerStartLat': passengerStartLat,
        'passengerStartLng': passengerStartLng,
        'passengerEndLat': passengerEndLat,
        'passengerEndLng': passengerEndLng,
        'passengerRideDistance': passengerRideDistance,
        'startCity': startCity,
        'endCity': endCity,
      };

      final response = await ApiClient.post('/ride-requests', body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return RideRequest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        _throwApiError(response.body, 'Failed to create ride request');
        throw Exception('unreachable');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /ride-requests/driver/{driverProfileId}/pending — pending requests
  /// for the driver's active rides.
  static Future<List<RideRequest>> getDriverPendingRequests(
      int driverProfileId) async {
    try {
      final response =
          await ApiClient.get('/ride-requests/driver/$driverProfileId/pending');

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) => RideRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _throwApiError(response.body, 'Failed to fetch pending requests');
        return [];
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// PUT /ride-requests/{id}/accept — driver accepts a ride request.
  static Future<RideRequest> acceptRequest(int requestId) async {
    try {
      final response =
          await ApiClient.put('/ride-requests/$requestId/accept');

      if (response.statusCode == 200) {
        return RideRequest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        _throwApiError(response.body, 'Failed to accept request');
        throw Exception('unreachable');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// PUT /ride-requests/{id}/reject — driver rejects a ride request.
  static Future<RideRequest> rejectRequest(int requestId) async {
    try {
      final response =
          await ApiClient.put('/ride-requests/$requestId/reject');

      if (response.statusCode == 200) {
        return RideRequest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        _throwApiError(response.body, 'Failed to reject request');
        throw Exception('unreachable');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /ride-requests/passenger/{userId} — passenger's own requests.
  static Future<List<RideRequest>> getPassengerRequests(int userId) async {
    try {
      final response =
          await ApiClient.get('/ride-requests/passenger/$userId');

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) => RideRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _throwApiError(response.body, 'Failed to fetch passenger requests');
        return [];
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ─── Private helper ──────────────────────────────────────────────

  static Never _throwApiError(String responseBody, String fallback) {
    try {
      final error = jsonDecode(responseBody);
      if (error is Map) {
        final msg = error['message'] ?? error['errorMessage'];
        if (msg != null) throw ApiException(msg.toString());
      }
    } catch (e) {
      if (e is ApiException) rethrow;
    }
    throw Exception(fallback);
  }
}

