/// Request model for confirming a passenger ride.
class PassengerRideConfirmRequest {
  final int rideDetailId;
  final int userId;
  final double startLocationLongitude;
  final double endLocationLongitude;
  final double passengerRideDistance;
  final double passengerCost;
  final String? startCity;
  final String? endCity;

  PassengerRideConfirmRequest({
    required this.rideDetailId,
    required this.userId,
    required this.startLocationLongitude,
    required this.endLocationLongitude,
    required this.passengerRideDistance,
    required this.passengerCost,
    this.startCity,
    this.endCity,
  });

  Map<String, dynamic> toJson() {
    return {
      'rideDetailId': rideDetailId,
      'userId': userId,
      'startLocationLongitude': startLocationLongitude,
      'endLocationLongitude': endLocationLongitude,
      'passengerRideDistance': passengerRideDistance,
      'passengerCost': passengerCost,
      'startCity': startCity,
      'endCity': endCity,
    };
  }
}

