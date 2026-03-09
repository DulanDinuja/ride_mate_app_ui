import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import '../models/send_verification_code_request.dart';
import '../models/verify_code_request.dart';
import 'login_success_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _codeControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _sendVerificationCode();
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _sendVerificationCode() async {
    setState(() => _isResending = true);
    try {
      final request = SendVerificationCodeRequest(email: widget.email);
      await ApiService.sendVerificationCode(request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _verifyEmail() async {
    String code = _codeControllers.map((controller) => controller.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = VerifyCodeRequest(email: widget.email, code: code);
      final response = await ApiService.verifyCode(request);
      
      if (mounted && response.isValid == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginSuccessScreen()),
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFF0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: screenHeight * 0.15,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4B6164), Color(0xFF1A2A33), Color(0xFF020D19)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Container(
                      width: 155,
                      height: 15,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFE2EB),
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Container(
              transform: Matrix4.translationValues(0, -40, 0),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFF0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Verify Your Email',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF040F1B),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF5A6B7C),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: "We've sent a 6-digit code to your email\n"),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF040F1B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          size: 120,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        6,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: _buildCodeBox(index),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Didn't receive the code?  ",
                          style: TextStyle(fontSize: 15, color: Color(0xFF5A6B7C)),
                        ),
                        GestureDetector(
                          onTap: _isResending ? null : _sendVerificationCode,
                          child: Text(
                            _isResending ? 'Sending...' : 'Resend Code',
                            style: TextStyle(
                              fontSize: 15,
                              color: _isResending ? Colors.grey : const Color(0xFF00BFA5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    CustomButton(
                      text: _isLoading ? 'Verifying...' : 'Verify Email',
                      onPressed: _isLoading ? () {} : _verifyEmail,
                      backgroundColor: const Color(0xFF040F1B),
                      textColor: Colors.white,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeBox(int index) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNodes[index].hasFocus ? const Color(0xFF00BFA5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _codeControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF040F1B),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          _onCodeChanged(value, index);
          if (value.isEmpty) {
            _onBackspace(value, index);
          }
        },
      ),
    );
  }
}
