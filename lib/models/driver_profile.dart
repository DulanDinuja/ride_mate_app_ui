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

  bool get isTwoWheeler => vehicleTypeCode?.toUpperCase() == 'BIKE';

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] as int,
      userId: json['userId'] as int,
      driverProfileCompleted: json['driverProfileCompleted'] as String,
      vehicleTypeCode: json['vehicleTypeCode'] as String?,
    );
  }
}
