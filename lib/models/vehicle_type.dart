class VehicleType {
  final int id;
  final String code;
  final String name;
  final String status;

  const VehicleType({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
    );
  }
}
