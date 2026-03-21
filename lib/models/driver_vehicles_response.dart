class DriverVehicle {
  final int id;
  final String vehicleTypeName;
  final String vehicleMakeName;
  final String vehicleModelName;
  final String registrationNumber;
  final String color;
  final int year;
  final int seats;
  final String isVerified;
  final String isPrimary;
  final String status;

  const DriverVehicle({
    required this.id,
    required this.vehicleTypeName,
    required this.vehicleMakeName,
    required this.vehicleModelName,
    required this.registrationNumber,
    required this.color,
    required this.year,
    required this.seats,
    required this.isVerified,
    required this.isPrimary,
    required this.status,
  });

  factory DriverVehicle.fromJson(Map<String, dynamic> json) => DriverVehicle(
        id: json['id'] as int,
        vehicleTypeName: json['vehicleTypeName'] as String? ?? '',
        vehicleMakeName: json['vehicleMakeName'] as String? ?? '',
        vehicleModelName: json['vehicleModelName'] as String? ?? '',
        registrationNumber: json['registrationNumber'] as String? ?? '',
        color: json['color'] as String? ?? '',
        year: json['year'] as int? ?? 0,
        seats: json['seats'] as int? ?? 0,
        isVerified: json['isVerified'] as String? ?? 'NO',
        isPrimary: json['isPrimary'] as String? ?? 'NO',
        status: json['status'] as String? ?? '',
      );

  String get displayName => '$vehicleMakeName $vehicleModelName ($registrationNumber)';
}

class DriverVehiclesResponse {
  final int driverProfileId;
  final bool hasMultipleVehicles;
  final int totalVehicles;
  final List<DriverVehicle> vehicles;

  const DriverVehiclesResponse({
    required this.driverProfileId,
    required this.hasMultipleVehicles,
    required this.totalVehicles,
    required this.vehicles,
  });

  factory DriverVehiclesResponse.fromJson(Map<String, dynamic> json) =>
      DriverVehiclesResponse(
        driverProfileId: json['driverProfileId'] as int,
        hasMultipleVehicles: json['hasMultipleVehicles'] as bool? ?? false,
        totalVehicles: json['totalVehicles'] as int? ?? 0,
        vehicles: (json['vehicles'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DriverVehicle.fromJson)
            .toList(),
      );
}
