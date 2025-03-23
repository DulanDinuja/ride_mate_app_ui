/// Real-time driver location update received via WebSocket.
///
/// Matches the JSON payload published to `/topic/ride/{rideId}/location`.
class DriverLocationUpdate {
  final int rideId;
  final double latitude;
  final double longitude;
  final double bearing;
  final int timestamp; // epoch millis

  const DriverLocationUpdate({
    required this.rideId,
    required this.latitude,
    required this.longitude,
    this.bearing = 0.0,
    required this.timestamp,
  });

  factory DriverLocationUpdate.fromJson(Map<String, dynamic> json) {
    return DriverLocationUpdate(
      rideId: (json['rideId'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
      timestamp: (json['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'rideId': rideId,
        'latitude': latitude,
        'longitude': longitude,
        'bearing': bearing,
        'timestamp': timestamp,
      };

  @override
  String toString() =>
      'DriverLocationUpdate(rideId=$rideId, lat=$latitude, lng=$longitude, '
      'bearing=$bearing, ts=$timestamp)';
}

