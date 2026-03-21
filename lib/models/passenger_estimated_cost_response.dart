/// Response model for GET /ride-requests/{rideDetailId}/estimate-cost
/// Matches backend PassengerEstimatedCostResponse.
class PassengerEstimatedCostResponse {
  final int rideDetailId;
  final int currentPassengerCount;
  final int projectedPassengerCount;
  final double perKmRate;
  final double passengerRideDistance;
  final double sharePercentage;
  final double estimatedCost;
  final String? pricingNote;

  const PassengerEstimatedCostResponse({
    required this.rideDetailId,
    required this.currentPassengerCount,
    required this.projectedPassengerCount,
    required this.perKmRate,
    required this.passengerRideDistance,
    required this.sharePercentage,
    required this.estimatedCost,
    this.pricingNote,
  });

  factory PassengerEstimatedCostResponse.fromJson(Map<String, dynamic> json) {
    return PassengerEstimatedCostResponse(
      rideDetailId: (json['rideDetailId'] as num).toInt(),
      currentPassengerCount: (json['currentPassengerCount'] as num?)?.toInt() ?? 0,
      projectedPassengerCount:
          (json['projectedPassengerCount'] as num?)?.toInt() ?? 1,
      perKmRate: (json['perKmRate'] as num?)?.toDouble() ?? 0.0,
      passengerRideDistance:
          (json['passengerRideDistance'] as num?)?.toDouble() ?? 0.0,
      sharePercentage: (json['sharePercentage'] as num?)?.toDouble() ?? 0.0,
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      pricingNote: json['pricingNote'] as String?,
    );
  }
}

