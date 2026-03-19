/// Response model for the ride price calculation API.
class RidePriceCalculationResponse {
  final double? totalRidePrice;
  final double? perKmRate;
  final double? totalDistance;
  final String? vehicleTypeName;

  RidePriceCalculationResponse({
    this.totalRidePrice,
    this.perKmRate,
    this.totalDistance,
    this.vehicleTypeName,
  });

  factory RidePriceCalculationResponse.fromJson(Map<String, dynamic> json) {
    return RidePriceCalculationResponse(
      totalRidePrice: (json['totalRidePrice'] as num?)?.toDouble(),
      perKmRate: (json['perKmRate'] as num?)?.toDouble(),
      totalDistance: (json['totalDistance'] as num?)?.toDouble(),
      vehicleTypeName: json['vehicleTypeName'] as String?,
    );
  }
}

