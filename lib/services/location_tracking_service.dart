import 'dart:convert';
import 'dart:developer' as dev;

import '../models/api_exception.dart';
import '../models/driver_location_update.dart';
import 'api_client.dart';
import 'stomp_service.dart';

/// High-level service for driver live-location sharing.
///
/// **Driver side** — publishes location via WebSocket:
/// ```dart
/// await LocationTrackingService.startPublishing(rideId: 42);
/// LocationTrackingService.publishLocation(rideId: 42, lat: 6.9, lng: 79.8, bearing: 45);
/// LocationTrackingService.stopPublishing();
/// ```
///
/// **Passenger side** — subscribes to driver location:
/// ```dart
/// final initial = await LocationTrackingService.getLatestDriverLocation(42);
/// await LocationTrackingService.startTracking(rideId: 42);
/// final handle = LocationTrackingService.subscribeToDriverLocation(
///   rideId: 42,
///   onUpdate: (update) => print(update),
/// );
/// handle.unsubscribe(); // when leaving the screen
/// LocationTrackingService.stopTracking();
/// ```
class LocationTrackingService {
  LocationTrackingService._();

  // ─── Driver: publish location ────────────────────────────────────

  /// Activate STOMP connection (call once when navigation starts).
  static Future<void> startPublishing({required int rideId}) async {
    await StompService.instance.activate();
    dev.log(
      '[LocationTracking] Publishing started for ride #$rideId',
      name: 'LocationTracking',
    );
  }

  /// Send a single location update through the WebSocket.
  static void publishLocation({
    required int rideId,
    required double latitude,
    required double longitude,
    double bearing = 0.0,
  }) {
    final payload = {
      'rideId': rideId,
      'latitude': latitude,
      'longitude': longitude,
      'bearing': bearing,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    StompService.instance.send('/app/ride/$rideId/location', payload);
  }

  /// Disconnect (call when navigation ends).
  static void stopPublishing() {
    StompService.instance.deactivate();
    dev.log('[LocationTracking] Publishing stopped', name: 'LocationTracking');
  }

  // ─── Passenger: subscribe to driver location ─────────────────────

  /// Activate STOMP connection (call once when tracking screen opens).
  static Future<void> startTracking({required int rideId}) async {
    await StompService.instance.activate();
    dev.log(
      '[LocationTracking] Tracking started for ride #$rideId',
      name: 'LocationTracking',
    );
  }

  /// Subscribe to live driver-location updates for a ride.
  ///
  /// Returns a handle to unsubscribe when done.
  static StompUnsubscribeHandle subscribeToDriverLocation({
    required int rideId,
    required void Function(DriverLocationUpdate update) onUpdate,
  }) {
    return StompService.instance.subscribe(
      '/topic/ride/$rideId/location',
      (body) {
        try {
          final update = DriverLocationUpdate.fromJson(body);
          onUpdate(update);
        } catch (e) {
          dev.log(
            '[LocationTracking] parse error: $e',
            name: 'LocationTracking',
          );
        }
      },
    );
  }

  /// Disconnect (call when tracking screen closes).
  static void stopTracking() {
    StompService.instance.deactivate();
    dev.log('[LocationTracking] Tracking stopped', name: 'LocationTracking');
  }

  // ─── REST: fetch initial / latest location ───────────────────────

  /// GET /ride-details/{rideDetailId}/driver-location
  ///
  /// Returns the latest cached driver location from the server (Redis).
  /// Use this to place the driver marker before the WebSocket connects.
  static Future<DriverLocationUpdate?> getLatestDriverLocation(
    int rideDetailId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/ride-details/$rideDetailId/driver-location',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DriverLocationUpdate.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // no cached location yet
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['errorMessage'];
          if (msg != null) throw ApiException(msg.toString());
        }
        return null;
      }
    } catch (e) {
      dev.log(
        '[LocationTracking] getLatestDriverLocation error: $e',
        name: 'LocationTracking',
      );
      return null;
    }
  }
}

