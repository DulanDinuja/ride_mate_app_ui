/// Model for an available ride shown to passengers browsing rides.
/// Matches backend SharedRidePoolResponse from GET /shared-ride/available.
class AvailableRide {
  final int rideDetailId;
  final int? driverProfileId;
  final String? startCity;
  final String? endCity;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String? startTime;
  final int currentPassengers;
  final int availableSeats;
  final double totalRideDistance;
  final double totalRideCost;
  final double perKmRate;
  /// Pre-calculated estimated cost for this passenger (based on passengerRideDistance)
  final double? estimatedCostPerPassenger;
  final double driverRating;
  final int totalRidesAsDriver;
  final double? mlAcceptanceProbability;
  final int? mlRank;

  // Driver/vehicle info — populated from AvailableRideResponse fields when available
  final String driverFirstName;
  final String driverLastName;
  final String? driverGender;
  final String? driverProfileImageUrl;
  final String? vehicleTypeName;
  final String? vehicleMakeName;
  final String? vehicleModelName;
  final String? vehicleColor;
  final String? vehiclePlateNumber;
  final String? status;

  const AvailableRide({
    required this.rideDetailId,
    this.driverProfileId,
    this.startCity,
    this.endCity,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    this.startTime,
    required this.currentPassengers,
    required this.availableSeats,
    required this.totalRideDistance,
    required this.totalRideCost,
    required this.perKmRate,
    this.estimatedCostPerPassenger,
    required this.driverRating,
    required this.totalRidesAsDriver,
    this.mlAcceptanceProbability,
    this.mlRank,
    this.driverFirstName = '',
    this.driverLastName = '',
    this.driverGender,
    this.driverProfileImageUrl,
    this.vehicleTypeName,
    this.vehicleMakeName,
    this.vehicleModelName,
    this.vehicleColor,
    this.vehiclePlateNumber,
    this.status,
  });

  bool get isFemaleDriver => driverGender == 'FEMALE';
  bool get isMaleDriver => driverGender == 'MALE';

  String get driverGenderLabel {
    if (driverGender == 'FEMALE') return '♀ Female';
    if (driverGender == 'MALE') return '♂ Male';
    return '';
  }

  String get driverFullName {
    if (driverFirstName.isEmpty && driverLastName.isEmpty) return 'Driver';
    return '$driverFirstName $driverLastName'.trim();
  }

  int get seatsRemaining => availableSeats - currentPassengers;

  String get vehicleDescription {
    final parts = <String>[];
    if (vehicleMakeName != null) parts.add(vehicleMakeName!);
    if (vehicleModelName != null) parts.add(vehicleModelName!);
    if (vehicleColor != null) parts.add('(${vehicleColor!})');
    return parts.isEmpty ? 'Vehicle' : parts.join(' ');
  }

  factory AvailableRide.fromJson(Map<String, dynamic> json) {
    return AvailableRide(
      rideDetailId: (json['rideDetailId'] as num).toInt(),
      driverProfileId: (json['driverProfileId'] as num?)?.toInt(),
      startCity: json['startCity'] as String?,
      endCity: json['endCity'] as String?,
      startLat: (json['startLocationLatitude'] as num?)?.toDouble() ??
          (json['startLat'] as num?)?.toDouble() ?? 0.0,
      startLng: (json['startLocationLongitude'] as num?)?.toDouble() ??
          (json['startLng'] as num?)?.toDouble() ?? 0.0,
      endLat: (json['endLocationLatitude'] as num?)?.toDouble() ??
          (json['endLat'] as num?)?.toDouble() ?? 0.0,
      endLng: (json['endLocationLongitude'] as num?)?.toDouble() ??
          (json['endLng'] as num?)?.toDouble() ?? 0.0,
      startTime: json['startTime']?.toString(),
      currentPassengers: (json['currentPassengers'] as num?)?.toInt() ?? 0,
      availableSeats: (json['availableSeats'] as num?)?.toInt() ?? 3,
      totalRideDistance: (json['totalRideDistance'] as num?)?.toDouble() ?? 0.0,
      totalRideCost: (json['totalRideCost'] as num?)?.toDouble() ?? 0.0,
      perKmRate: (json['perKmRate'] as num?)?.toDouble() ?? 0.0,
      estimatedCostPerPassenger:
          (json['estimatedCostPerPassenger'] as num?)?.toDouble(),
      driverRating: (json['driverRating'] as num?)?.toDouble() ?? 0.0,
      totalRidesAsDriver: (json['totalRidesAsDriver'] as num?)?.toInt() ?? 0,
      mlAcceptanceProbability:
          (json['mlAcceptanceProbability'] as num?)?.toDouble(),
      mlRank: (json['mlRank'] as num?)?.toInt(),
      driverFirstName: json['driverFirstName'] as String? ?? '',
      driverLastName: json['driverLastName'] as String? ?? '',
      driverGender: json['driverGender'] as String?,
      driverProfileImageUrl: json['driverProfileImageUrl'] as String?,
      vehicleTypeName: json['vehicleTypeName'] as String?,
      vehicleMakeName: json['vehicleMakeName'] as String?,
      vehicleModelName: json['vehicleModelName'] as String?,
      vehicleColor: json['vehicleColor'] as String?,
      vehiclePlateNumber: json['vehiclePlateNumber'] as String?,
      status: json['status'] as String?,
    );
  }
}
