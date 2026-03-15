class ApiResponse {
  final String? id;
  final String? messages;
  final String? details;
  final String? code;
  final bool? isValid;

  ApiResponse({
    this.id,
    this.messages,
    this.details,
    this.code,
    this.isValid,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      id: json['id']?.toString(),
      messages: json['messages'] as String?,
      details: json['details'] as String?,
      code: json['code'] as String?,
      isValid: json['isValid'] as bool?,
    );
  }
}

class LoginResponse {
  final String message;
  final bool success;
  final bool? emailVerified;
  final String? email;
  final String? token;
  final String? details;
  final String? code;
  final String? userRole;
  final bool? profileCompleted;
  final bool? registrationCompleted;

  LoginResponse({
    required this.message,
    required this.success,
    this.emailVerified,
    this.email,
    this.token,
    this.details,
    this.code,
    this.userRole,
    this.profileCompleted,
    this.registrationCompleted,
  });

  static bool? _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] as String? ?? json['messages'] as String? ?? 'Login response',
      success: json['success'] as bool? ?? false,
      emailVerified: _readBool(json['emailVerified']),
      email: json['email'] as String?,
      token: json['token'] as String?,
      details: json['details'] as String?,
      code: json['code'] as String?,
      userRole: json['userRole']?.toString(),
      profileCompleted: _readBool(json['profileCompleted'] ?? json['isProfileCompleted']),
      registrationCompleted: _readBool(
        json['registrationCompleted'] ?? json['isRegistrationCompleted'],
      ),
    );
  }
}
