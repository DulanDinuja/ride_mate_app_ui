/// Model for an available ride shown to passengers browsing rides.
/// Matches backend AvailableRideResponse.
class AvailableRide {
  final int rideDetailId;
  final String driverFirstName;
  final String driverLastName;
  final String? driverProfileImageUrl;
  final double driverRating;
  final int totalRidesAsDriver;
  final String? vehicleTypeName;
  final String? vehicleMakeName;
  final String? vehicleModelName;
  final String? vehicleColor;
  final String? vehiclePlateNumber;
  final String? startCity;
  final String? endCity;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final double totalRideDistance;
  final double totalRideCost;
  final double perKmRate;
  final int availableSeats;
  final int currentPassengers;
  final String? startTime;
  final String? status;

  const AvailableRide({
    required this.rideDetailId,
    required this.driverFirstName,
    required this.driverLastName,
    this.driverProfileImageUrl,
    required this.driverRating,
    required this.totalRidesAsDriver,
    this.vehicleTypeName,
    this.vehicleMakeName,
    this.vehicleModelName,
    this.vehicleColor,
    this.vehiclePlateNumber,
    this.startCity,
    this.endCity,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.totalRideDistance,
    required this.totalRideCost,
    required this.perKmRate,
    required this.availableSeats,
    required this.currentPassengers,
    this.startTime,
    this.status,
  });

  String get driverFullName => '$driverFirstName $driverLastName';

  int get seatsRemaining => availableSeats - currentPassengers;

  String get vehicleDescription {
    final parts = <String>[];
    if (vehicleMakeName != null) parts.add(vehicleMakeName!);
    if (vehicleModelName != null) parts.add(vehicleModelName!);
    if (vehicleColor != null) parts.add('($vehicleColor)');
    return parts.isEmpty ? 'Unknown Vehicle' : parts.join(' ');
  }

  factory AvailableRide.fromJson(Map<String, dynamic> json) {
    return AvailableRide(
      rideDetailId: json['rideDetailId'] as int,
      driverFirstName: json['driverFirstName'] as String? ?? '',
      driverLastName: json['driverLastName'] as String? ?? '',
      driverProfileImageUrl: json['driverProfileImageUrl'] as String?,
      driverRating: (json['driverRating'] as num?)?.toDouble() ?? 0.0,
      totalRidesAsDriver: (json['totalRidesAsDriver'] as num?)?.toInt() ?? 0,
      vehicleTypeName: json['vehicleTypeName'] as String?,
      vehicleMakeName: json['vehicleMakeName'] as String?,
      vehicleModelName: json['vehicleModelName'] as String?,
      vehicleColor: json['vehicleColor'] as String?,
      vehiclePlateNumber: json['vehiclePlateNumber'] as String?,
      startCity: json['startCity'] as String?,
      endCity: json['endCity'] as String?,
      startLat: (json['startLat'] as num?)?.toDouble() ?? 0.0,
      startLng: (json['startLng'] as num?)?.toDouble() ?? 0.0,
      endLat: (json['endLat'] as num?)?.toDouble() ?? 0.0,
      endLng: (json['endLng'] as num?)?.toDouble() ?? 0.0,
      totalRideDistance: (json['totalRideDistance'] as num?)?.toDouble() ?? 0.0,
      totalRideCost: (json['totalRideCost'] as num?)?.toDouble() ?? 0.0,
      perKmRate: (json['perKmRate'] as num?)?.toDouble() ?? 0.0,
      availableSeats: (json['availableSeats'] as num?)?.toInt() ?? 0,
      currentPassengers: (json['currentPassengers'] as num?)?.toInt() ?? 0,
      startTime: json['startTime'] as String?,
      status: json['status'] as String?,
    );
  }
}

