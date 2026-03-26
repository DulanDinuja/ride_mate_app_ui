import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/routes/app_routes.dart';
import '../models/api_exception.dart';
import '../models/send_verification_code_request.dart';
import '../models/verify_code_request.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_button.dart';

/// The fixed RideMate admin inbox that receives all admin verification codes.
const String _kAdminInbox = 'info.ridemate@gmail.com';

/// Email-verification screen for admin registration.
///
/// The 6-digit code is always sent to [_kAdminInbox]; the [registeredEmail]
/// is only displayed so the admin knows which account they just created.
class AdminEmailVerificationScreen extends StatefulWidget {
  /// The email address the admin registered with (for display only).
  final String registeredEmail;

  const AdminEmailVerificationScreen({
    super.key,
    required this.registeredEmail,
  });

  @override
  State<AdminEmailVerificationScreen> createState() =>
      _AdminEmailVerificationScreenState();
}

class _AdminEmailVerificationScreenState
    extends State<AdminEmailVerificationScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  bool _isAdminInboxStep = false;

  String get _currentVerificationEmail =>
      (_isAdminInboxStep ? _kAdminInbox : widget.registeredEmail)
          .trim()
          .toLowerCase();

  String get _stepLabel => _isAdminInboxStep ? 'Step 2 of 2' : 'Step 1 of 2';

  // ─── lifecycle ──────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _sendVerificationCode();
  }

  @override
  void dispose() {
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  // ─── API calls ──────────────────────────────────────────────────

  /// Sends (or re-sends) the code to the current verification email.
  Future<void> _sendVerificationCode() async {
    setState(() => _isResending = true);
    try {
      await AuthService.sendVerificationCode(
        SendVerificationCodeRequest(email: _currentVerificationEmail),
      );
      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Verification code sent to $_currentVerificationEmail',
        );
      }
    } on ApiException catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.message);
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          e.toString().replaceAll('Exception: ', '').replaceAll(
                'Network error: Exception: ',
                '',
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  /// Verifies the entered code for the active step.
  Future<void> _verifyCode() async {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length != 6) {
      SnackBarHelper.showWarning(
          context, 'Please enter the complete 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userIdRaw = await TokenService.getUserId();
      final userId = int.tryParse(userIdRaw ?? '');

      final response = await AuthService.verifyCode(
        VerifyCodeRequest(
          email: _currentVerificationEmail,
          code: code,
          userId: userId,
        ),
      );

      if (!mounted) return;

      if (response.isValid == true) {
        if (!_isAdminInboxStep) {
          SnackBarHelper.showSuccess(
            context,
            'User email verified. Now verify $_kAdminInbox',
          );

          // Move to step 2 and send a fresh code to the admin inbox.
          for (final controller in _codeControllers) {
            controller.clear();
          }

          setState(() => _isAdminInboxStep = true);
          _focusNodes.first.requestFocus();
          await _sendVerificationCode();
        } else {
          SnackBarHelper.showSuccess(context, 'Verification successful!');
          // Navigate to admin dashboard, clearing the entire back-stack.
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.adminDashboard,
            (route) => false,
          );
        }
      } else {
        SnackBarHelper.showError(
          context,
          response.messages ?? 'Verification failed. Please try again.',
        );
      }
    } on ApiException catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.message);
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          e.toString().replaceAll('Exception: ', '').replaceAll(
                'Network error: Exception: ',
                '',
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── key navigation helpers ─────────────────────────────────────

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

  // ─── build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFF0),
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────────
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

          // ── Draggable sheet ──────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.55,
            maxChildSize: 0.97,
            snap: true,
            snapSizes: const [0.55, 0.85, 0.97],
            builder: (ctx, scrollController) {
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
                    // Grabber bar
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 20),
                        children: [
                          // Back button
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: CustomBackButton(),
                          ),
                          const SizedBox(height: 8),

                          // Title
                          Text(
                            _isAdminInboxStep
                                ? 'Admin Inbox Verification'
                                : 'User Email Verification',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF040F1B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _stepLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF03AF74),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Subtitle
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF5A6B7C),
                                height: 1.6,
                              ),
                              children: [
                                TextSpan(
                                  text: _isAdminInboxStep
                                      ? 'A 6-digit verification code has been sent to the\nRide Mate admin inbox:\n'
                                      : 'A 6-digit verification code has been sent to:\n',
                                ),
                                TextSpan(
                                  text: _currentVerificationEmail,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF040F1B),
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      _isAdminInboxStep
                                          ? '\n\nRegistered account:\n${widget.registeredEmail}'
                                          : '\n\nAfter this step, verify $_kAdminInbox.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8A9BAC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Illustration
                          Container(
                            height: 220,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isAdminInboxStep
                                        ? Icons.admin_panel_settings_rounded
                                        : Icons.mark_email_read_outlined,
                                    size: 80,
                                    color: Color(0xFF03AF74),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _isAdminInboxStep
                                        ? 'Check your admin inbox'
                                        : 'Check the user inbox',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4B6164),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // 6-digit code boxes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              6,
                              (i) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _buildCodeBox(i),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Resend row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Didn't receive the code?  ",
                                style: TextStyle(
                                    fontSize: 15, color: Color(0xFF5A6B7C)),
                              ),
                              GestureDetector(
                                onTap: _isResending
                                    ? null
                                    : _sendVerificationCode,
                                child: Text(
                                  _isResending ? 'Sending...' : 'Resend Code',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _isResending
                                        ? Colors.grey
                                        : const Color(0xFF00BFA5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),

                          // Verify button
                          CustomButton(
                            text: _isLoading
                                ? 'Verifying...'
                                : (_isAdminInboxStep
                                    ? 'Verify & Go to Dashboard'
                                    : 'Verify User Email'),
                            onPressed: _isLoading ? () {} : _verifyCode,
                            backgroundColor: const Color(0xFF040F1B),
                            textColor: Colors.white,
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

  Widget _buildCodeBox(int index) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? const Color(0xFF03AF74)
              : Colors.transparent,
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
          if (value.isEmpty) _onBackspace(value, index);
        },
      ),
    );
  }
}



