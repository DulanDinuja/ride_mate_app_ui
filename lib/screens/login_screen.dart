import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import '../models/login_request.dart';
import 'signup_screen.dart';
import 'login_success_screen.dart';

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
    setState(() => _isLoading = true);

    try {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final response = await ApiService.loginUser(request);
      
      if (mounted && response.success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginSuccessScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFF0), // Cream/Ivory background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Top Section
            Container(
              height: screenHeight * 0.35,
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

            // White Container
            Container(
              transform: Matrix4.translationValues(0, -40, 0),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFF0), // Cream/Ivory background
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      keyboardType: TextInputType.emailAddress,
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
                          // TODO: Implement forgot password
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
                            print('Sign up button pressed'); // Debug print
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
            ),
          ],
        ),
      ),
    );
  }
}

