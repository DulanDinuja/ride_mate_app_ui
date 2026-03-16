class UserVerificationArgs {
  const UserVerificationArgs({
    required this.documentTypeId,
    required this.documentType,
    required this.idNumber,
    required this.gender,
    required this.willingToDrive,
  });

  final int documentTypeId;
  final String documentType;
  final String idNumber;
  final String gender;
  final bool willingToDrive;
}

