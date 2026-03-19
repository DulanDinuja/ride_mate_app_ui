/// Request model for creating a ride detail (driver starts a ride).
class RideDetailRequest {
  final int driverProfileId;
  final double startLocationLongitude;
  final double endLocationLongitude;
  final double startLocationLatitude;
  final double endLocationLatitude;
  final String startCity;
  final int availableSeats;
  final String startTime;
  final double totalRideDistance;
  final String tripRoute;
  final String status;
  final double totalRideCost;

  RideDetailRequest({
    required this.driverProfileId,
    required this.startLocationLongitude,
    required this.endLocationLongitude,
    required this.startLocationLatitude,
    required this.endLocationLatitude,
    required this.startCity,
    required this.availableSeats,
    required this.startTime,
    required this.totalRideDistance,
    required this.tripRoute,
    required this.status,
    required this.totalRideCost,
  });

  Map<String, dynamic> toJson() {
    return {
      'driverProfileId': driverProfileId,
      'startLocationLongitude': startLocationLongitude,
      'endLocationLongitude': endLocationLongitude,
      'startLocationLatitude': startLocationLatitude,
      'endLocationLatitude': endLocationLatitude,
      'startCity': startCity,
      'availableSeats': availableSeats,
      'startTime': startTime,
      'totalRideDistance': totalRideDistance,
      'tripRoute': tripRoute,
      'status': status,
      'totalRideCost': totalRideCost,
    };
  }
}

