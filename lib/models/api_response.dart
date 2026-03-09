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

  LoginResponse({
    required this.message,
    required this.success,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] as String,
      success: json['success'] as bool,
    );
  }
}
