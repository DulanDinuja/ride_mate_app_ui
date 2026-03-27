import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

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

class SetNewPasswordScreen extends StatefulWidget {
  final String email;

  const SetNewPasswordScreen({super.key, required this.email});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  bool _loading = false;

  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
        email: widget.email,
        newPassword: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      // Pop back to the login screen (removes both this screen and forgot password)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
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
        fontSize: 11,
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFFAAAAAA), size: 18),
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
                  top: domeH * 0.25,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Enter\nNew Password',
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
                        'Set a complex password to\nprotect your account',
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
            'assets/images/enter_new_password_screen_element.png',
            height: size.height * 0.25,
            fit: BoxFit.contain,
          ),

          // ── Form ─────────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Spacer(),

                  // Password field
                  Text('Password',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4A5F63))),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: const Color(0xFF1E2939)),
                      decoration: _inputDecoration(
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFFAAAAAA),
                            size: 16,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Confirm password field
                  Text('Confirm Password',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4A5F63))),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: TextField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: const Color(0xFF1E2939)),
                      decoration: _inputDecoration(
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFFAAAAAA),
                            size: 16,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Action button ──────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _resetPassword,
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
                              'Reset Password',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
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

