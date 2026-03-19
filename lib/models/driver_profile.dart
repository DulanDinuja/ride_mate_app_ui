class DriverProfile {
  final int id;
  final int userId;
  final String driverProfileCompleted;
  final String? vehicleTypeCode;

  const DriverProfile({
    required this.id,
    required this.userId,
    required this.driverProfileCompleted,
    this.vehicleTypeCode,
  });

  bool get isDriverProfileCompleted => driverProfileCompleted == 'YES';

  /// Returns true when the driver's vehicle is a two-wheeler (e.g. bike/scooter).
  bool get isTwoWheeler {
    final code = vehicleTypeCode?.toUpperCase();
    return code == 'BIKE' || code == 'SCOOTER' || code == 'TWO_WHEELER';
  }

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] as int,
      userId: json['userId'] as int,
      driverProfileCompleted: json['driverProfileCompleted'] as String,
      vehicleTypeCode: json['vehicleTypeCode'] as String?,
    );
  }
}
