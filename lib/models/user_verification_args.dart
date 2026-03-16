class UserVerificationArgs {
  const UserVerificationArgs({
    required this.documentTypeId,
    required this.documentType,
    required this.idNumber,
    required this.gender,
    required this.userRole,
    required this.dateOfBirth,
    this.selfieDocumentId,
  });

  final int documentTypeId;
  final String documentType;
  final String idNumber;
  final String gender;
  final String userRole;

  /// ISO-8601 date string, e.g. "1995-06-15"
  final String dateOfBirth;

  /// Document ID returned by the server after uploading the selfie.
  final int? selfieDocumentId;
}

