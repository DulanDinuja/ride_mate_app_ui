class DriverProfile {
  final int id;
  final int userId;
  final String driverProfileCompleted;

  const DriverProfile({
    required this.id,
    required this.userId,
    required this.driverProfileCompleted,
  });

  bool get isDriverProfileCompleted => driverProfileCompleted == 'YES';

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] as int,
      userId: json['userId'] as int,
      driverProfileCompleted: json['driverProfileCompleted'] as String,
    );
  }
}
