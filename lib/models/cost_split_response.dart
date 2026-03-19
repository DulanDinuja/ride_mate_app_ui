/// Response model for the ride cost-split calculation API.
///
/// Contains the full segment-by-segment cost breakdown for a ride,
/// showing how costs are distributed among the driver and all passengers.
class CostSplitResponse {
  final int? rideDetailId;
  final double? totalRideCost;
  final double? totalRideDistance;
  final double? perKmRate;
  final double? driverEffectiveCost;
  final String? driverStartCity;
  final int? totalPassengers;
  final List<SegmentDetail> segments;
  final List<PassengerCostDetail> passengerCosts;

  CostSplitResponse({
    this.rideDetailId,
    this.totalRideCost,
    this.totalRideDistance,
    this.perKmRate,
    this.driverEffectiveCost,
    this.driverStartCity,
    this.totalPassengers,
    this.segments = const [],
    this.passengerCosts = const [],
  });

  factory CostSplitResponse.fromJson(Map<String, dynamic> json) {
    return CostSplitResponse(
      rideDetailId: json['rideDetailId'] as int?,
      totalRideCost: (json['totalRideCost'] as num?)?.toDouble(),
      totalRideDistance: (json['totalRideDistance'] as num?)?.toDouble(),
      perKmRate: (json['perKmRate'] as num?)?.toDouble(),
      driverEffectiveCost: (json['driverEffectiveCost'] as num?)?.toDouble(),
      driverStartCity: json['driverStartCity'] as String?,
      totalPassengers: json['totalPassengers'] as int?,
      segments: (json['segments'] as List<dynamic>?)
              ?.map((e) => SegmentDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      passengerCosts: (json['passengerCosts'] as List<dynamic>?)
              ?.map((e) =>
                  PassengerCostDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Represents one segment between two consecutive waypoints on the route.
class SegmentDetail {
  final int? segmentOrder;
  final String? startLabel;
  final String? endLabel;
  final double? distanceKm;
  final int? riderCount;
  final double? segmentCost;
  final double? costPerRider;

  SegmentDetail({
    this.segmentOrder,
    this.startLabel,
    this.endLabel,
    this.distanceKm,
    this.riderCount,
    this.segmentCost,
    this.costPerRider,
  });

  factory SegmentDetail.fromJson(Map<String, dynamic> json) {
    return SegmentDetail(
      segmentOrder: json['segmentOrder'] as int?,
      startLabel: json['startLabel'] as String?,
      endLabel: json['endLabel'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      riderCount: json['riderCount'] as int?,
      segmentCost: (json['segmentCost'] as num?)?.toDouble(),
      costPerRider: (json['costPerRider'] as num?)?.toDouble(),
    );
  }
}

/// Represents the cost breakdown for a single passenger.
class PassengerCostDetail {
  final int? userId;
  final int? shareRideDetailId;
  final String? startCity;
  final String? endCity;
  final double? passengerRideDistance;
  final double? totalPassengerCost;
  final List<PassengerSegmentCost> segmentBreakdown;

  PassengerCostDetail({
    this.userId,
    this.shareRideDetailId,
    this.startCity,
    this.endCity,
    this.passengerRideDistance,
    this.totalPassengerCost,
    this.segmentBreakdown = const [],
  });

  factory PassengerCostDetail.fromJson(Map<String, dynamic> json) {
    return PassengerCostDetail(
      userId: json['userId'] as int?,
      shareRideDetailId: json['shareRideDetailId'] as int?,
      startCity: json['startCity'] as String?,
      endCity: json['endCity'] as String?,
      passengerRideDistance:
          (json['passengerRideDistance'] as num?)?.toDouble(),
      totalPassengerCost: (json['totalPassengerCost'] as num?)?.toDouble(),
      segmentBreakdown: (json['segmentBreakdown'] as List<dynamic>?)
              ?.map((e) =>
                  PassengerSegmentCost.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Individual segment cost for a passenger.
class PassengerSegmentCost {
  final int? segmentOrder;
  final String? startLabel;
  final String? endLabel;
  final double? distanceKm;
  final int? riderCount;
  final double? passengerShareForSegment;

  PassengerSegmentCost({
    this.segmentOrder,
    this.startLabel,
    this.endLabel,
    this.distanceKm,
    this.riderCount,
    this.passengerShareForSegment,
  });

  factory PassengerSegmentCost.fromJson(Map<String, dynamic> json) {
    return PassengerSegmentCost(
      segmentOrder: json['segmentOrder'] as int?,
      startLabel: json['startLabel'] as String?,
      endLabel: json['endLabel'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      riderCount: json['riderCount'] as int?,
      passengerShareForSegment:
          (json['passengerShareForSegment'] as num?)?.toDouble(),
    );
  }
}

