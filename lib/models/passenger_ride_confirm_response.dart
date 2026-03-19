/// Response model after a passenger confirms a ride.
class PassengerRideConfirmResponse {
  final int? shareRideDetailId;
  final int? rideDetailId;
  final int? userId;
  final double? passengerCost;
  final double? passengerRideDistance;
  final String? startCity;
  final String? endCity;
  final String? status;
  final String? message;

  PassengerRideConfirmResponse({
    this.shareRideDetailId,
    this.rideDetailId,
    this.userId,
    this.passengerCost,
    this.passengerRideDistance,
    this.startCity,
    this.endCity,
    this.status,
    this.message,
  });

  factory PassengerRideConfirmResponse.fromJson(Map<String, dynamic> json) {
    return PassengerRideConfirmResponse(
      shareRideDetailId: json['shareRideDetailId'] as int?,
      rideDetailId: json['rideDetailId'] as int?,
      userId: json['userId'] as int?,
      passengerCost: (json['passengerCost'] as num?)?.toDouble(),
      passengerRideDistance: (json['passengerRideDistance'] as num?)?.toDouble(),
      startCity: json['startCity'] as String?,
      endCity: json['endCity'] as String?,
      status: json['status'] as String?,
      message: json['message'] as String?,
    );
  }
}

