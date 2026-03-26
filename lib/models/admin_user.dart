class AdminUser {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String userRole;
  final String status;
  final String emailVerified;
  final String? createdDate;
  final String? lastLoginDate;

  const AdminUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.userRole,
    required this.status,
    required this.emailVerified,
    this.createdDate,
    this.lastLoginDate,
  });

  String get fullName => ('$firstName $lastName').trim();

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      userRole: json['userRole']?.toString() ?? 'UNKNOWN',
      status: json['status']?.toString() ?? 'UNKNOWN',
      emailVerified: json['emailVerified']?.toString() ?? 'UNKNOWN',
      createdDate: json['createdDate']?.toString(),
      lastLoginDate: json['lastLoginDate']?.toString(),
    );
  }

  AdminUser copyWith({
    String? status,
  }) {
    return AdminUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      userRole: userRole,
      status: status ?? this.status,
      emailVerified: emailVerified,
      createdDate: createdDate,
      lastLoginDate: lastLoginDate,
    );
  }
}

