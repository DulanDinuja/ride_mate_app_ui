import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../models/send_verification_code_request.dart';
import '../models/verify_code_request.dart';
import 'login_screen.dart';
import 'login_success_screen.dart';
import '../models/api_exception.dart';
import '../utils/snackbar_helper.dart';

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

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback? onVerified;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.onVerified,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // Rebuild border colour when focus changes
    for (final node in _focusNodes) {
      node.addListener(() => setState(() {}));
    }
    _sendVerificationCode();
  }

  @override
  void dispose() {
    for (final c in _codeControllers) c.dispose();
    for (final n in _focusNodes) n.dispose();
    super.dispose();
  }

  // ── Network calls ──────────────────────────────────────────────────────────

  void _sendVerificationCode() async {
    setState(() => _isResending = true);
    try {
      await AuthService.sendVerificationCode(
          SendVerificationCodeRequest(email: widget.email));
      if (mounted) {
        SnackBarHelper.showSuccess(
            context, 'Verification code sent to your email!');
      }
    } on ApiException catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.message);
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          e.toString()
              .replaceAll('Exception: ', '')
              .replaceAll('Network error: Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _verifyEmail() async {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length != 6) {
      SnackBarHelper.showWarning(
          context, 'Please enter the complete 6-digit code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.verifyCode(
          VerifyCodeRequest(email: widget.email, code: code));

      if (mounted) {
        if (response.isValid == true) {
          SnackBarHelper.showSuccess(context, 'Email verified successfully!');
          if (widget.onVerified != null) {
            widget.onVerified!();
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const LoginSuccessScreen()),
            );
          }
        } else {
          SnackBarHelper.showError(
            context,
            response.messages ?? 'Verification failed. Please try again.',
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.message);
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          e.toString()
              .replaceAll('Exception: ', '')
              .replaceAll('Network error: Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onBackspace(String value, int index) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
          // ── Dome ──────────────────────────────────────────────────────────
          SizedBox(
            height: domeH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipPath(
                  clipper: _DomeClipper(),
                  child: const ColoredBox(color: Color(0xFF0D0D0D)),
                ),
                // Title + subtitle
                Positioned(
                  top: domeH * 0.25,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Verify Your Email',
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
                        "Enter the 6-digit code sent to\n${widget.email}",
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

          const SizedBox(height: 20),

          // ── Illustration ───────────────────────────────────────────────────
          Image.asset(
            'assets/images/email_verification_element.png',
            height: size.height * 0.28,
            fit: BoxFit.contain,
          ),

          // ── OTP + Actions ──────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // OTP boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      6,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _buildCodeBox(index),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Resend row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code?  ",
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF5A6B7C)),
                      ),
                      GestureDetector(
                        onTap: _isResending ? null : _sendVerificationCode,
                        child: Text(
                          _isResending ? 'Sending...' : 'Resend Code',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _isResending
                                ? Colors.grey
                                : const Color(0xFF2ECC40),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D0D0D),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF0D0D0D).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Verify Email',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Back to  ',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF5A6B7C)),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        ),
                        child: Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF2ECC40),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── OTP box widget ─────────────────────────────────────────────────────────

  Widget _buildCodeBox(int index) {
    final isFocused = _focusNodes[index].hasFocus;
    final hasText   = _codeControllers[index].text.isNotEmpty;

    return Container(
      width: 40,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFocused
            ? const Color(0xFF0D0D0D).withValues(alpha: 0.06)
            : const Color(0xFFEFF1E3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF0D0D0D)
              : hasText
                  ? const Color(0xFF2ECC40)
                  : Colors.transparent,
          width: 1.8,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF0D0D0D).withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _codeControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0D0D0D),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {}); // refresh border colour
          _onCodeChanged(value, index);
          if (value.isEmpty) _onBackspace(value, index);
        },
      ),
    );
  }
}
