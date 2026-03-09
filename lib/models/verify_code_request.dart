class VerifyCodeRequest {
  final String email;
  final String code;
  final int? userId;

  VerifyCodeRequest({
    required this.email,
    required this.code,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'code': code,
    if (userId != null) 'userId': userId,
  };
}
