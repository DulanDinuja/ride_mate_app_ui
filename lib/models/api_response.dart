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
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
  final int? expiresIn;
  final int? userId;
  final String? userName;
  final String? email;
  final String? role;
  final String? emailVerified;

  LoginResponse({
    required this.message,
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.expiresIn,
    this.userId,
    this.userName,
    this.email,
    this.role,
    this.emailVerified,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] as String? ?? json['messages'] as String? ?? 'Login response',
      success: json['success'] as bool? ?? false,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      tokenType: json['tokenType'] as String?,
      expiresIn: json['expiresIn'] as int?,
      userId: json['userId'] as int?,
      userName: json['userName'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      emailVerified: json['emailVerified'] as String?,
    );
  }

  bool get isEmailVerified => emailVerified?.toUpperCase() == 'YES';
}
