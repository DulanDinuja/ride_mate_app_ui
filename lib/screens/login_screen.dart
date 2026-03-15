import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../models/api_response.dart';
import '../services/auth_service.dart';
import '../models/login_request.dart';
import '../models/send_verification_code_request.dart';
import 'signup_screen.dart';
import 'login_success_screen.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';
import '../models/api_exception.dart';
import '../utils/snackbar_helper.dart';

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

  bool _requiresProfileCompletion(String? message) {
    if (message == null) return false;
    final normalized = message.toLowerCase();
    return normalized.contains('complete your profile') ||
        normalized.contains('complete profile') ||
        normalized.contains('complete your registration') ||
        normalized.contains('complete registration') ||
        normalized.contains('profile incomplete') ||
        normalized.contains('registration incomplete') ||
        normalized.contains('finish registration') ||
        normalized.contains('finish profile');
  }

  bool _requiresProfileCompletionFromResponse(LoginResponse response) {
    final completionFlagIndicatesIncomplete =
        response.profileCompleted == false || response.registrationCompleted == false;

    return completionFlagIndicatesIncomplete ||
        _requiresProfileCompletion(response.message) ||
        _requiresProfileCompletion(response.details) ||
        _requiresProfileCompletion(response.code);
  }

  String _profileCompletionMessage(LoginResponse response) {
    if (response.message.trim().isNotEmpty) return response.message;
    if ((response.details ?? '').trim().isNotEmpty) return response.details!;
    return 'Please complete your profile to continue.';
  }

  void _redirectToRegistrationScreen(String message) {
    if (!mounted) return;

    setState(() => _isLoading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _handleLogin() async {
    // Validate fields
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
      // Attempt login
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final response = await AuthService.loginUser(request);
      final responseMessage = _profileCompletionMessage(response);
      final requiresProfileCompletion = _requiresProfileCompletionFromResponse(response);

      if (mounted && requiresProfileCompletion) {
        _redirectToRegistrationScreen(responseMessage);
        return;
      }


      if (mounted && response.success) {
        // Login successful - proceed to success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginSuccessScreen(),
          ),
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
        final failureMessage = response.message.trim().isEmpty
            ? 'Login failed. Please try again.'
            : response.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failureMessage),
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
        String errorMessage = e.toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Network error: Exception: ', '');

        if (_requiresProfileCompletion(errorMessage)) {
          _redirectToRegistrationScreen(errorMessage);

        // Check if error is about email not verified
        } else if (errorMessage.toLowerCase().contains('email not verified') ||
            errorMessage.toLowerCase().contains('verify your email')) {

          // Step 2: Email not verified - send verification code automatically
          setState(() => _isLoading = true); // Keep loading state
          await _sendVerificationCodeAndRedirect();
          
        } else {
          // Show other errors (wrong password, user not found, etc.)
          setState(() => _isLoading = false);
          SnackBarHelper.showError(context, errorMessage);
        }
      }
    }
  }

  // Send verification code and redirect to verification screen
  Future<void> _sendVerificationCodeAndRedirect() async {
    try {
      print('Sending verification code to: ${_emailController.text.trim()}');
      
      // Send verification code
      final sendRequest = SendVerificationCodeRequest(email: _emailController.text.trim());
      await AuthService.sendVerificationCode(sendRequest);
      
      print('Verification code sent successfully');
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Redirect to email verification screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
        
        // Show success message
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            SnackBarHelper.showWarning(context, 'Verification code sent! Please check your email.');
          }
        });
      }
    } catch (e) {
      print('Error sending verification code: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        // If sending fails, still redirect but show error
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            SnackBarHelper.showWarning(context, 'Please verify your email. You can resend the code from the verification screen.');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFF0),
      body: Stack(
        children: [
          // Gradient Background
          Container(
            height: screenHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4B6164),
                  Color(0xFF1A2A33),
                  Color(0xFF020D19),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Bottom Sheet Content
          DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            snap: true,
            snapSizes: const [0.5, 0.75, 0.95],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFF0),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // iOS-style grabber
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),

                    // Scrollable content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(32.0),
                        children: [
                          const SizedBox(height: 8),

                          // Welcome Back Title
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF040F1B),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle
                          const Text(
                            'Sign in to continue your journey',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4A6063),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Email Label
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4A5F63),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Email Input Field
                          CustomTextField(
                            controller: _emailController,
                            hintText: 'your.email@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.text,
                          ),

                          const SizedBox(height: 16),

                          // Password Label
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4A5F63),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Password Input Field
                          CustomTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF4A6063),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Color(0xFF4A6063),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login Button
                          CustomButton(
                            text: _isLoading ? 'Logging in...' : 'Login',
                            onPressed: _isLoading ? () {} : _handleLogin,
                            backgroundColor: const Color(0xFF040F1B),
                          ),

                          const SizedBox(height: 24),

                          // OR Divider
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey[300],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Color(0xFF4A6063),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Google Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () {
                                // TODO: Implement Google sign in
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF4A6063), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/google_icon.png',
                                    height: 24,
                                    width: 24,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.g_mobiledata,
                                        size: 32,
                                        color: Color(0xFF4A6063),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      color: Color(0xFF040F1B),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Sign Up Text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Color(0xFF4A6063),
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignupScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: Color(0xFF040F1B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

