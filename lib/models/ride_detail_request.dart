/// Request model for creating a ride detail (driver starts a ride).
/// Matches backend RideDetailRequestResource.
class RideDetailRequest {
  final int driverProfileId;
  final double startLocationLongitude;
  final double endLocationLongitude;
  final double startLocationLatitude;
  final double endLocationLatitude;
  final String startCity;
  final String? endCity;
  final int availableSeats;
  final String startTime;
  final double totalRideDistance;
  final String tripRoute;
  final String status;
  final double totalRideCost;
  final double? perKmRate;
  final int? vehicleId;

  RideDetailRequest({
    required this.driverProfileId,
    required this.startLocationLongitude,
    required this.endLocationLongitude,
    required this.startLocationLatitude,
    required this.endLocationLatitude,
    required this.startCity,
    this.endCity,
    required this.availableSeats,
    required this.startTime,
    required this.totalRideDistance,
    required this.tripRoute,
    required this.status,
    required this.totalRideCost,
    this.perKmRate,
    this.vehicleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'driverProfileId': driverProfileId,
      'startLocationLongitude': startLocationLongitude,
      'endLocationLongitude': endLocationLongitude,
      'startLocationLatitude': startLocationLatitude,
      'endLocationLatitude': endLocationLatitude,
      'startCity': startCity,
      if (endCity != null) 'endCity': endCity,
      'availableSeats': availableSeats,
      'startTime': startTime,
      'totalRideDistance': totalRideDistance,
      'tripRoute': tripRoute,
      'status': status,
      'totalRideCost': totalRideCost,
      if (perKmRate != null) 'perKmRate': perKmRate,
      if (vehicleId != null) 'vehicleId': vehicleId,
    };
  }
}

