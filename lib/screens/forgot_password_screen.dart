import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import '../models/send_verification_code_request.dart';
import '../models/verify_code_request.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // 0 = send code, 1 = verify code, 2 = new password
  int _step = 0;
  bool _loading = false;

  String _email = '';
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final email = await TokenService.getEmail();
    if (email != null && mounted) setState(() => _email = email);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendCode() async {
    if (_email.isEmpty) {
      _showError('Could not determine your email. Please log in again.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.sendVerificationCode(
        SendVerificationCodeRequest(email: _email),
      );
      setState(() => _step = 1);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showError('Please enter the verification code.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.verifyCode(VerifyCodeRequest(email: _email, code: code));
      setState(() => _step = 2);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      _showError('Please fill in both password fields.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.resetPassword(email: _email, newPassword: password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4B6164), Color(0xFF1A2A33), Color(0xFF020D19)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(42)),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 120,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.all(Radius.circular(100)),
                ),
              ),
            ),
            Positioned(
              top: 48,
              left: 20,
              child: SafeArea(
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                ),
              ),
            ),
            Positioned.fill(
              top: 170,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFFF0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(44),
                    topRight: Radius.circular(44),
                    bottomLeft: Radius.circular(42),
                    bottomRight: Radius.circular(42),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFE2EB),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(child: _ResetPasswordIllustration()),
                      const SizedBox(height: 22),
                      Center(
                        child: Text(
                          _step == 0
                              ? 'Reset Password'
                              : _step == 1
                                  ? 'Enter Verification Code'
                                  : 'Enter New Password',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF040F1B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          _step == 0
                              ? 'A verification code will be sent to\n$_email'
                              : _step == 1
                                  ? 'Enter the code sent to $_email'
                                  : 'Set a complex password to protect your account',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF4A6063)),
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (_step == 1) ...[
                        const Text('Verification Code',
                            style: TextStyle(fontSize: 16, color: Color(0xFF4A5565))),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 16, color: Color(0xFF1E2939)),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFEFF1E3),
                            hintText: '6-digit code',
                            prefixIcon: const Icon(Icons.pin_outlined, color: Color(0xFF99A1AF)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          ),
                        ),
                      ],
                      if (_step == 2) ...[
                        const Text('Password',
                            style: TextStyle(fontSize: 16, color: Color(0xFF4A5565))),
                        const SizedBox(height: 10),
                        _PasswordInput(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 24),
                        const Text('Confirm Password',
                            style: TextStyle(fontSize: 16, color: Color(0xFF4A5565))),
                        const SizedBox(height: 10),
                        _PasswordInput(
                          controller: _confirmController,
                          obscureText: _obscureConfirm,
                          onToggleVisibility: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ],
                      const SizedBox(height: 34),
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _loading
                              ? null
                              : _step == 0
                                  ? _sendCode
                                  : _step == 1
                                      ? _verifyCode
                                      : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF040F1B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _step == 0
                                      ? 'Send Verification Code'
                                      : _step == 1
                                          ? 'Verify Code'
                                          : 'Reset Password',
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w500),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  const _PasswordInput({
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
  });

  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      obscuringCharacter: '*',
      style: const TextStyle(fontSize: 16, color: Color(0xFF1E2939)),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFEFF1E3),
        hintText: '........',
        hintStyle: const TextStyle(color: Color(0xFF9AA1AA), fontSize: 26),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF99A1AF)),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}

class _ResetPasswordIllustration extends StatelessWidget {
  const _ResetPasswordIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE4EBE4),
            ),
          ),
          Positioned(
            bottom: 16,
            child: Container(
              width: 170,
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFFC9D7D8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0F5F59), width: 8),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CONFIRM\nPASSWORD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF0F5F59),
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 10),
                  Icon(Icons.password, color: Color(0xFF0F5F59), size: 30),
                ],
              ),
            ),
          ),
          const Positioned(
            right: 44,
            top: 42,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF7FD8C4),
              child: Icon(Icons.check, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
