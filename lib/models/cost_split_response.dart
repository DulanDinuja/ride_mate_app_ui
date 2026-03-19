/// Response model for the segment-based cost split API.
/// Mirrors the backend CostSplitResponse exactly.
class CostSplitResponse {
  final int rideDetailId;
  final double totalRideCost;
  final double totalRideDistance;
  final double perKmRate;
  final double driverEffectiveCost;
  final String? driverStartCity;
  final int totalPassengers;
  final List<SegmentDetail> segments;
  final List<PassengerCostDetail> passengerCosts;

  CostSplitResponse({
    required this.rideDetailId,
    required this.totalRideCost,
    required this.totalRideDistance,
    required this.perKmRate,
    required this.driverEffectiveCost,
    this.driverStartCity,
    required this.totalPassengers,
    required this.segments,
    required this.passengerCosts,
  });

  factory CostSplitResponse.fromJson(Map<String, dynamic> json) {
    return CostSplitResponse(
      rideDetailId: (json['rideDetailId'] as num).toInt(),
      totalRideCost: (json['totalRideCost'] as num).toDouble(),
      totalRideDistance: (json['totalRideDistance'] as num).toDouble(),
      perKmRate: (json['perKmRate'] as num).toDouble(),
      driverEffectiveCost: (json['driverEffectiveCost'] as num).toDouble(),
      driverStartCity: json['driverStartCity'] as String?,
      totalPassengers: (json['totalPassengers'] as num).toInt(),
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

/// One segment between two consecutive waypoints on the driver's route.
class SegmentDetail {
  final int segmentOrder;
  final String? startLabel;
  final String? endLabel;
  final double distanceKm;
  final int riderCount;
  final double segmentCost;
  final double costPerRider;

  SegmentDetail({
    required this.segmentOrder,
    this.startLabel,
    this.endLabel,
    required this.distanceKm,
    required this.riderCount,
    required this.segmentCost,
    required this.costPerRider,
  });

  factory SegmentDetail.fromJson(Map<String, dynamic> json) {
    return SegmentDetail(
      segmentOrder: (json['segmentOrder'] as num).toInt(),
      startLabel: json['startLabel'] as String?,
      endLabel: json['endLabel'] as String?,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      riderCount: (json['riderCount'] as num).toInt(),
      segmentCost: (json['segmentCost'] as num).toDouble(),
      costPerRider: (json['costPerRider'] as num).toDouble(),
    );
  }
}

/// Cost breakdown for a single passenger.
class PassengerCostDetail {
  final int userId;
  final int shareRideDetailId;
  final String? startCity;
  final String? endCity;
  final double passengerRideDistance;
  final double totalPassengerCost;
  final List<PassengerSegmentCost> segmentBreakdown;

  PassengerCostDetail({
    required this.userId,
    required this.shareRideDetailId,
    this.startCity,
    this.endCity,
    required this.passengerRideDistance,
    required this.totalPassengerCost,
    required this.segmentBreakdown,
  });

  factory PassengerCostDetail.fromJson(Map<String, dynamic> json) {
    return PassengerCostDetail(
      userId: (json['userId'] as num).toInt(),
      shareRideDetailId: (json['shareRideDetailId'] as num).toInt(),
      startCity: json['startCity'] as String?,
      endCity: json['endCity'] as String?,
      passengerRideDistance:
          (json['passengerRideDistance'] as num).toDouble(),
      totalPassengerCost:
          (json['totalPassengerCost'] as num).toDouble(),
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
  final int segmentOrder;
  final String? startLabel;
  final String? endLabel;
  final double distanceKm;
  final int riderCount;
  final double passengerShareForSegment;

  PassengerSegmentCost({
    required this.segmentOrder,
    this.startLabel,
    this.endLabel,
    required this.distanceKm,
    required this.riderCount,
    required this.passengerShareForSegment,
  });

  factory PassengerSegmentCost.fromJson(Map<String, dynamic> json) {
    return PassengerSegmentCost(
      segmentOrder: (json['segmentOrder'] as num).toInt(),
      startLabel: json['startLabel'] as String?,
      endLabel: json['endLabel'] as String?,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      riderCount: (json['riderCount'] as num).toInt(),
      passengerShareForSegment:
          (json['passengerShareForSegment'] as num).toDouble(),
    );
  }
}

