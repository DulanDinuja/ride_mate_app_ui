import 'dart:convert';
import 'dart:developer' as dev;

import '../models/api_exception.dart';
import '../models/available_ride.dart';
import '../models/passenger_estimated_cost_response.dart';
import '../models/ride_request.dart';
import '../models/shared_ride_detail.dart';
import 'api_client.dart';

/// Handles all ride-request-related API calls (authenticated).
class RideRequestService {
  // ─────────────────────────────────────────────────────────────────
  //  03 — Passenger: Discover rides
  // ─────────────────────────────────────────────────────────────────

  /// GET /shared-ride/available — get ML-ranked available rides.
  /// Matches Postman step 03 "Get Available Rides (ML-Ranked)".
  static Future<List<AvailableRide>> getAvailableRides({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required double passengerRideDistance,
    double radius = 15,
  }) async {
    try {
      final query = 'startLat=$startLat'
          '&startLng=$startLng'
          '&endLat=$endLat'
          '&endLng=$endLng'
          '&passengerRideDistance=$passengerRideDistance'
          '&radius=$radius';

      dev.log('[RideRequestService] GET /shared-ride/available?$query',
          name: 'RideRequestService');

      final response =
          await ApiClient.get('/shared-ride/available?$query');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((e) => AvailableRide.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        _throwApiError(response.body, 'Failed to fetch available rides');
        return []; // unreachable
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  03 — Passenger: Estimate cost before requesting
  // ─────────────────────────────────────────────────────────────────

  /// GET /ride-requests/{rideDetailId}/estimate-cost — estimate passenger cost.
  /// Matches Postman step 03 "Estimate My Cost Before Requesting".
  static Future<PassengerEstimatedCostResponse> estimateCost({
    required int rideDetailId,
    required double passengerRideDistance,
  }) async {
    try {
      final response = await ApiClient.get(
        '/ride-requests/$rideDetailId/estimate-cost'
        '?passengerRideDistance=$passengerRideDistance',
      );

      if (response.statusCode == 200) {
        return PassengerEstimatedCostResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        _throwApiError(response.body, 'Failed to estimate cost');
        throw Exception('unreachable');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  04 — Passenger: Send ride request
  // ─────────────────────────────────────────────────────────────────

  /// POST /ride-requests — create a ride request.
  /// Matches Postman step 04 "Create Ride Request".
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

  /// GET /ride-requests/passenger/{userId} — passenger's own requests.
  /// Matches Postman step 04 "Get My Requests (Passenger)".
  static Future<List<RideRequest>> getPassengerRequests(int userId) async {
    try {
      final response =
          await ApiClient.get('/ride-requests/passenger/$userId');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((e) => RideRequest.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        _throwApiError(response.body, 'Failed to fetch passenger requests');
        return [];
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  05 — Driver: Accept or Reject
  // ─────────────────────────────────────────────────────────────────

  /// GET /ride-requests/driver/{driverProfileId}/pending — pending requests.
  /// Matches Postman step 05 "Get Pending Requests (Driver)".
  static Future<List<RideRequest>> getDriverPendingRequests(
      int driverProfileId) async {
    try {
      final response = await ApiClient.get(
          '/ride-requests/driver/$driverProfileId/pending');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((e) => RideRequest.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
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
  /// Returns RideRequest with estimatedCost populated.
  /// Matches Postman step 05 "Accept Ride Request".
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
  /// Matches Postman step 05 "Reject Ride Request".
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

  // ─────────────────────────────────────────────────────────────────
  //  08 — Passenger: Cancel Request
  // ─────────────────────────────────────────────────────────────────

  /// PUT /ride-requests/{id}/cancel — passenger cancels their request.
  /// Works for both PENDING and ACCEPTED status.
  /// Matches Postman step 08 "Cancel Ride Request".
  static Future<RideRequest> cancelRequest(int requestId) async {
    try {
      final response =
          await ApiClient.put('/ride-requests/$requestId/cancel');

      if (response.statusCode == 200) {
        return RideRequest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        _throwApiError(response.body, 'Failed to cancel request');
        throw Exception('unreachable');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  07 & 09 — Shared ride info and status
  // ─────────────────────────────────────────────────────────────────

  /// GET /shared-ride/history/{userId} — passenger ride history.
  /// Matches Postman step 07 "Get Passenger Ride History".
  static Future<List<SharedRideDetail>> getPassengerRideHistory(
      int userId) async {
    try {
      final response =
          await ApiClient.get('/shared-ride/history/$userId');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((e) =>
                  SharedRideDetail.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        _throwApiError(response.body, 'Failed to fetch ride history');
        return [];
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /shared-ride/details/{shareRideDetailId} — single shared ride detail.
  /// Matches Postman step 07 "Get Shared Ride Details".
  static Future<SharedRideDetail> getSharedRideDetails(
      int shareRideDetailId) async {
    try {
      final response =
          await ApiClient.get('/shared-ride/details/$shareRideDetailId');

      if (response.statusCode == 200) {
        return SharedRideDetail.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        _throwApiError(response.body, 'Failed to fetch shared ride details');
        throw Exception('unreachable');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// PUT /shared-ride/{shareRideDetailId}/cancel — cancel a shared ride record.
  /// Matches Postman step 08 "Cancel Shared Ride (After Join)".
  static Future<void> cancelSharedRide(int shareRideDetailId) async {
    try {
      final response =
          await ApiClient.put('/shared-ride/$shareRideDetailId/cancel');

      if (response.statusCode >= 200 && response.statusCode < 300) return;

      _throwApiError(response.body, 'Failed to cancel shared ride');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// PUT /shared-ride/{shareRideDetailId}/confirm — confirm a shared ride.
  /// Matches Postman step 09 "Confirm Shared Ride".
  static Future<void> confirmSharedRide(int shareRideDetailId) async {
    try {
      final response =
          await ApiClient.put('/shared-ride/$shareRideDetailId/confirm');

      if (response.statusCode >= 200 && response.statusCode < 300) return;

      _throwApiError(response.body, 'Failed to confirm shared ride');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  07 — Shared Ride Info
  // ─────────────────────────────────────────────────────────────────

  /// GET /shared-ride/passengers/{rideDetailId} — get all passengers on a ride.
  /// Matches Postman step 07 "Get All Passengers on Ride".
  static Future<List<SharedRideDetail>> getPassengersOnRide(
      int rideDetailId) async {
    try {
      final response =
          await ApiClient.get('/shared-ride/passengers/$rideDetailId');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((e) =>
                  SharedRideDetail.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        _throwApiError(response.body, 'Failed to fetch passengers on ride');
        return [];
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  09 — Shared Ride Status Updates
  // ─────────────────────────────────────────────────────────────────

  /// PUT /shared-ride/{shareRideDetailId}/status — update shared ride status.
  /// Matches Postman step 09 "Update Shared Ride Status (Generic)".
  static Future<void> updateSharedRideStatus(
      int shareRideDetailId, String status) async {
    try {
      final response = await ApiClient.put(
        '/shared-ride/$shareRideDetailId/status',
        body: {'status': status},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) return;

      _throwApiError(response.body, 'Failed to update shared ride status');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Private helpers
  // ─────────────────────────────────────────────────────────────────

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
