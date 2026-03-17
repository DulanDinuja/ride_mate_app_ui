class UserProfile {
  final int id;
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
  final int? userVerificationImageDocumentId;
  final String? userVerificationImageUrl;
  final String createdDate;

  const UserProfile({
    required this.id,
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
    this.userVerificationImageDocumentId,
    this.userVerificationImageUrl,
    required this.createdDate,
  });

  bool get isProfileCompleted => userProfileCompleted == 'YES';

  // bool get isProfileCompleted =>
  //     userProfileCompleted == 'YES' ||
  //         (dateOfBirth.trim().isNotEmpty && gender.trim().isNotEmpty);

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      userId: json['userId'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      emailVerified: json['emailVerified'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      gender: json['gender'] as String,
      preferredLanguage: json['preferredLanguage'] as String,
      userProfileCompleted: json['userProfileCompleted'] as String,
      userVerificationImageDocumentId:
          json['userVerificationImageDocumentId'] as int?,
      userVerificationImageUrl: json['userVerificationImageUrl'] as String?,
      createdDate: json['createdDate'] as String,
    );
  }
}
