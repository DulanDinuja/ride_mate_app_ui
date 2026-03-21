class UserProfile {
  final int id;
  final int? version;
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String role;
  final String status;
  final String emailVerified;
  final String dateOfBirth;
  final String gender;
  final String preferredLanguage;
  final String userProfileCompleted;
  final String willingToDrive;
  final int? identificationTypeId;
  final String? identificationTypeName;
  final String? identificationNumber;
  final String? identificationFrontImageUrl;
  final String? identificationBackImageUrl;
  final int? userVerificationImageDocumentId;
  final String? userVerificationImageUrl;
  final int? profileImageDocumentId;
  final String? profileImageUrl;
  final String createdDate;

  const UserProfile({
    required this.id,
    this.version,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.status,
    required this.emailVerified,
    required this.dateOfBirth,
    required this.gender,
    required this.preferredLanguage,
    required this.userProfileCompleted,
    required this.willingToDrive,
    this.identificationTypeId,
    this.identificationTypeName,
    this.identificationNumber,
    this.identificationFrontImageUrl,
    this.identificationBackImageUrl,
    this.userVerificationImageDocumentId,
    this.userVerificationImageUrl,
    this.profileImageDocumentId,
    this.profileImageUrl,
    required this.createdDate,
  });

  bool get isProfileCompleted => userProfileCompleted == 'YES';
  bool get isWillingToDrive => willingToDrive == 'YES';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      version: json['version'] as int?,
      userId: json['userId'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      emailVerified: json['emailVerified'] as String,
      dateOfBirth: (json['dateOfBirth'] as String?) ?? '',
      gender: (json['gender'] as String?) ?? '',
      preferredLanguage: (json['preferredLanguage'] as String?) ?? 'EN',
      userProfileCompleted: (json['userProfileCompleted'] as String?) ?? 'NO',
      willingToDrive: (json['willingToDrive'] as String?) ?? 'NO',
      identificationTypeId: json['identificationTypeId'] as int?,
      identificationTypeName: json['identificationTypeName'] as String?,
      identificationNumber: json['identificationNumber'] as String?,
      identificationFrontImageUrl: json['identificationFrontImageUrl'] as String?,
      identificationBackImageUrl: json['identificationBackImageUrl'] as String?,
      userVerificationImageDocumentId: json['userVerificationImageDocumentId'] as int?,
      userVerificationImageUrl: json['userVerificationImageUrl'] as String?,
      profileImageDocumentId: json['profileImageDocumentId'] as int?,
      profileImageUrl: json['profileImageUrl'] as String?,
      createdDate: (json['createdDate'] as String?) ?? '',
    );
  }
}
