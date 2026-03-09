class SendVerificationCodeRequest {
  final String email;

  SendVerificationCodeRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}
