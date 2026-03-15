class UserVerificationArgs {
  const UserVerificationArgs({
    required this.documentType,
    required this.idNumber,
    required this.gender,
    required this.willingToDrive,
  });

  final String documentType;
  final String idNumber;
  final String gender;
  final bool willingToDrive;
}

