class AdminDriverProfile {
  final int id;
  final int? userId;
  final String fullName;
  final String accountStatus;
  final String? email;
  final String? phoneNumber;

  const AdminDriverProfile({
    required this.id,
    this.userId,
    required this.fullName,
    required this.accountStatus,
    this.email,
    this.phoneNumber,
  });

  factory AdminDriverProfile.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString() ??
        json['userFirstName']?.toString() ??
        '';
    final lastName = json['lastName']?.toString() ??
        json['userLastName']?.toString() ??
        '';

    return AdminDriverProfile(
      id: (json['id'] as num?)?.toInt() ??
          (json['driverProfileId'] as num?)?.toInt() ??
          0,
      userId: (json['userId'] as num?)?.toInt(),
      fullName: (json['userFullName']?.toString() ?? '$firstName $lastName').trim(),
      accountStatus: json['accountStatus']?.toString() ?? 'UNKNOWN',
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
    );
  }
}

