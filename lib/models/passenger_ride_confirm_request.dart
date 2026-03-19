/// Request model for confirming a passenger ride.
class PassengerRideConfirmRequest {
  final int rideDetailId;
  final int userId;
  final double startLocationLongitude;
  final double startLocationLatitude;
  final double endLocationLongitude;
  final double endLocationLatitude;
  final double passengerRideDistance;
  final String? startCity;
  final String? endCity;

  PassengerRideConfirmRequest({
    required this.rideDetailId,
    required this.userId,
    required this.startLocationLongitude,
    required this.startLocationLatitude,
    required this.endLocationLongitude,
    required this.endLocationLatitude,
    required this.passengerRideDistance,
    this.startCity,
    this.endCity,
  });

  Map<String, dynamic> toJson() {
    return {
      'rideDetailId': rideDetailId,
      'userId': userId,
      'startLocationLongitude': startLocationLongitude,
      'startLocationLatitude': startLocationLatitude,
      'endLocationLongitude': endLocationLongitude,
      'endLocationLatitude': endLocationLatitude,
      'passengerRideDistance': passengerRideDistance,
      'startCity': startCity,
      'endCity': endCity,
    };
  }
}

