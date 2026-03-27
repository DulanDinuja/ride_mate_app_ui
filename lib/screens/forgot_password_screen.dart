import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'email_verification_screen.dart';

class _DomeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 60,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_DomeClipper oldClipper) => false;
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0; // 0 = email, 1 = set new password
  bool _loading = false;

  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }
    // Navigate to EmailVerificationScreen – it auto-sends the code and
    // calls onVerified when the user enters the correct code.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmailVerificationScreen(
          email: email,
          onVerified: () {
            Navigator.pop(context); // close verification screen
            setState(() => _step = 1); // advance to set-password step
          },
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirm  = _confirmController.text.trim();
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
      await AuthService.resetPassword(
        email: _emailController.text.trim(),
        newPassword: password,
      );
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

  String get _title => switch (_step) {
    0 => 'Reset\nYour Password',
    _ => 'Set New\nPassword',
  };

  String get _subtitle => switch (_step) {
    0 => "Enter your email address below\nand we'll send you a reset code",
    _ => 'Set a complex password to\nprotect your account',
  };

  String get _buttonLabel => switch (_step) {
    0 => 'Send Verification Code',
    _ => 'Reset Password',
  };

  void _onButtonPressed() {
    switch (_step) {
      case 0:  _sendCode();
      default: _resetPassword();
    }
  }

  // Shared rounded input decoration
  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFFAAAAAA),
        fontSize: 11,                          // reduced from 13
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFFAAAAAA), size: 18),  // reduced from 20
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFEFF1E3),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(color: Color(0xFF0D0D0D), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size  = MediaQuery.of(context).size;
    final domeH = size.height * 0.28;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFFFF0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Dome ────────────────────────────────────────────────────────────
          SizedBox(
            height: domeH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipPath(
                  clipper: _DomeClipper(),
                  child: const ColoredBox(color: Color(0xFF0D0D0D)),
                ),
                Positioned(
                  top: domeH * 0.16,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFFAAAAAA),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ── Illustration ─────────────────────────────────────────────────────
          Image.asset(
            'assets/images/reset_password_screen_element.png',
            height: size.height * 0.35,
            fit: BoxFit.contain,
          ),

          // ── Form ─────────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44), // reduced width (was 28)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Spacer(),

                  // ── Step 0: Email ──────────────────────────────────────────────
                  if (_step == 0) ...[
                    Text('Email',
                        style: GoogleFonts.poppins(
                            fontSize: 11,                          // reduced from 13
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4A5F63))),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: const Color(0xFF1E2939)), // reduced from 13
                        decoration: _inputDecoration(
                            hint: 'your.email@example.com',
                            prefixIcon: Icons.email_outlined),
                      ),
                    ),
                  ],

                  // ── Step 1: Set new password ───────────────────────────────────
                  if (_step == 1) ...[
                    Text('Password',
                        style: GoogleFonts.poppins(
                            fontSize: 11,                          // reduced from 13
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4A5F63))),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: const Color(0xFF1E2939)), // reduced from 13
                        decoration: _inputDecoration(
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFFAAAAAA),
                              size: 16,                            // reduced from 18
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Confirm Password',
                        style: GoogleFonts.poppins(
                            fontSize: 11,                          // reduced from 13
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4A5F63))),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: TextField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: const Color(0xFF1E2939)), // reduced from 13
                        decoration: _inputDecoration(
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFFAAAAAA),
                              size: 16,                            // reduced from 18
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Action button ──────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _onButtonPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D0D0D),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF0D0D0D).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              _buttonLabel,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,                    // reduced from 14
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3),
                            ),
                    ),
                  ),

                  const SizedBox(height: 70),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
