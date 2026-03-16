class IdentificationType {
  const IdentificationType({
    required this.id,
    required this.code,
    required this.name,
  });

  final int id;
  final String code;
  final String name;

  factory IdentificationType.fromJson(Map<String, dynamic> json) {
    return IdentificationType(
      id: (json['id'] as num).toInt(),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

