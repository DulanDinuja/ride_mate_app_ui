class VehicleModel {
  final int id;
  final String code;
  final String name;
  final String status;

  const VehicleModel({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
    );
  }
}
