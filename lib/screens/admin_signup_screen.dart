import 'package:flutter/material.dart';

import '../models/api_exception.dart';
import '../models/user_registration_request.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'admin_email_verification_screen.dart';

class AdminSignupScreen extends StatefulWidget {
  const AdminSignupScreen({super.key});

  @override
  State<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends State<AdminSignupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminSignup() async {
    if (!_agreedToTerms) {
      SnackBarHelper.showError(context, 'Please agree to the Terms & Conditions');
      return;
    }

    if (_firstNameController.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Please enter your first name');
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Please enter your last name');
      return;
    }

    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      SnackBarHelper.showError(context, 'Please enter a valid email address');
      return;
    }

    if (_phoneController.text.trim().length != 10 ||
        !RegExp(r'^[0-9]+$').hasMatch(_phoneController.text.trim())) {
      SnackBarHelper.showError(context, 'Phone number must be exactly 10 numbers');
      return;
    }

    if (_passwordController.text.length < 8) {
      SnackBarHelper.showError(context, 'Password must contain at least 8 characters');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      SnackBarHelper.showError(context, 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = UserRegistrationRequest(
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        userRole: UserRole.ADMIN,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      await AuthService.registerUser(request);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminEmailVerificationScreen(
            registeredEmail: _emailController.text.trim(),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('Network error: Exception: ', '');
      SnackBarHelper.showError(context, errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFF0),
      body: Stack(
        children: [
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 12),
              child: const Align(
                alignment: Alignment.topLeft,
                child: CustomBackButton(),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.55,
            maxChildSize: 0.95,
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
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(28.0, 22.0, 28.0, 48.0),
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Admin Sign Up',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF040F1B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Create an admin account using any email.\n'
                      'First verify the registered email, then verify the Ride Mate admin inbox.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF485D61),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'First Name',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4A5565),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _firstNameController,
                      hintText: 'First Name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Last Name',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4A5565),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _lastNameController,
                      hintText: 'Last Name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4A5565),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'admin@ridemate.com',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4A5565),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _phoneController,
                      hintText: '07XXXXXXXX',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4A5565),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4A5565),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    CheckboxListTile(
                      value: _agreedToTerms,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('I agree to Terms & Conditions'),
                      onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: _isLoading ? 'Creating account...' : 'Create Admin Account',
                      onPressed: _isLoading ? () {} : _handleAdminSignup,
                      backgroundColor: const Color(0xFF040F1B),
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

