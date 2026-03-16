class UserVerificationArgs {
  const UserVerificationArgs({
    required this.documentTypeId,
    required this.documentType,
    required this.idNumber,
    required this.gender,
    required this.userRole,
  });

  final int documentTypeId;
  final String documentType;
  final String idNumber;
  final String gender;
  final String userRole;
}

