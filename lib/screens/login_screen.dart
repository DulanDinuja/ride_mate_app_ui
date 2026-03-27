import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/config/app_config.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import '../models/login_request.dart';
import '../models/send_verification_code_request.dart';
import 'signup_screen.dart';
import 'login_success_screen.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';
import '../models/api_exception.dart';
import '../utils/snackbar_helper.dart';

// ── Dome clipper ─────────────────────────────────────────────────────────────
class _DomeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2, size.height + 60,
      size.width, size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_DomeClipper oldClipper) => false;
}

// ── Screen ───────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    debugPrint('>>> _handleLogin called, BASE_URL=${AppConfig.baseUrl}');

    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final response = await AuthService.loginUser(request);

      if (mounted && response.success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginSuccessScreen()),
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
        final msg = response.message.trim().isEmpty
            ? 'Login failed. Please try again.'
            : response.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Network error: Exception: ', '');

        if (errorMessage.toLowerCase().contains('email not verified') ||
            errorMessage.toLowerCase().contains('verify your email')) {
          setState(() => _isLoading = true);
          await _sendVerificationCodeAndRedirect();
        } else {
          setState(() => _isLoading = false);
          SnackBarHelper.showError(context, errorMessage);
        }
      }
    }
  }

  Future<void> _sendVerificationCodeAndRedirect() async {
    try {
      final sendRequest =
      SendVerificationCodeRequest(email: _emailController.text.trim());
      await AuthService.sendVerificationCode(sendRequest);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                EmailVerificationScreen(email: _emailController.text.trim()),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            SnackBarHelper.showWarning(
                context, 'Verification code sent! Please check your email.');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                EmailVerificationScreen(email: _emailController.text.trim()),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            SnackBarHelper.showWarning(context,
                'Please verify your email. You can resend the code from the verification screen.');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final domeHeight = size.height * 0.38;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFF0),
      body: Stack(
        children: [
          // ── Dome-shaped dark section ─────────────────────────────────
          ClipPath(
            clipper: _DomeClipper(),
            child: Container(
              width: size.width,
              height: domeHeight,
              color: const Color(0xFF0D0D0D),
            ),
          ),

          // ── Welcome text inside dome ─────────────────────────────────
          Positioned(
            top: domeHeight * 0.22,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sign in to continue your journey',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFAAAAAA),
                  ),
                ),
              ],
            ),
          ),

          // ── Back button ──────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 12),
              child: const CustomBackButton(),
            ),
          ),

          // ── Scrollable card + logo ───────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: domeHeight * 0.60,
                left: 36,
                right: 36,
                bottom: 32,
              ),
              child: Column(
                children: [
                  // Form card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFF0),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email
                        const _FieldLabel(label: 'Email'),
                        const SizedBox(height: 6),
                        CustomTextField(
                          controller: _emailController,
                          hintText: 'your.email@example.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 16),

                        // Password
                        const _FieldLabel(label: 'Password'),
                        const SizedBox(height: 6),
                        CustomTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF7A9096),
                              size: 18,
                            ),
                            onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                          ),
                        ),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const ForgotPasswordScreen()),
                            ),
                            style: TextButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(vertical: 2),
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF6B8083),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D0D0D),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                              const Color(0xFF0D0D0D).withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // OR divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                  color: Colors.grey[300], thickness: 1),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                  color: Colors.grey[300], thickness: 1),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Don't have an account
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignupScreen()),
                            ),
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: "Don't have an account? ",
                                    style:
                                    TextStyle(color: Color(0xFF6B8083)),
                                  ),
                                  TextSpan(
                                    text: 'Sign up',
                                    style: TextStyle(
                                      color: Color(0xFF2ECC40),
                                      fontWeight: FontWeight.w600,
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

                  const SizedBox(height: 250),

                  // RideMate logo
                  Image.asset(
                    'assets/images/Logo_Black.png',
                    height: 45,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field label helper ───────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF4A5F63),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}