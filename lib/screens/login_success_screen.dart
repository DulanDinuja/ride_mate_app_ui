import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/routes/app_routes.dart';
import '../models/user_profile.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';
class LoginSuccessScreen extends StatefulWidget {
  const LoginSuccessScreen({super.key});
  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}
class _LoginSuccessScreenState extends State<LoginSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }
  Future<void> _onLetsExplore() async {
    setState(() => _isLoading = true);
    UserProfile? foundProfile;
    try {
      final userId = await TokenService.getUserId();
      if (!mounted) return;
      if (userId != null) {
        try {
          foundProfile = await UserService.getUserProfileByUserId(userId);
        } catch (_) {
          // Profile record not found or network error — foundProfile stays null
        }
        if (!mounted) return;
        setState(() => _isLoading = false);
        // Profile exists and is marked complete by the server -> go straight to home
        if (foundProfile != null && foundProfile.isProfileCompleted) {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.userHomeMap, (route) => false);
          return;
        }
        // Profile missing or incomplete — show popup
        _showCompleteProfileSheet(foundProfile);
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
      _showCompleteProfileSheet(null);
    }
  }
  void _showCompleteProfileSheet(UserProfile? profile) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFF0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(
            28,
            20,
            28,
            28 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDFE2EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),
              // Icon
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFF040F1B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF040F1B),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              const Text(
                'Your profile is incomplete.\nPlease provide your details to start\nusing Ride Mate.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF4B6164),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              // Complete Now button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // close sheet
                    _navigateToCompletion(profile);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF040F1B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Complete Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
  /// Navigates to the profile completion screen.
  void _navigateToCompletion(UserProfile? profile) {
    // Always go to profile completion — pre-fill with existing data if available
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.profileCompletion,
      (route) => false,
      arguments: profile,
    );
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFF0),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success Illustration — full width, outside horizontal padding
            Image.asset(
              'assets/images/success_screen_element.png',
              width: screenWidth,
            ),

            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  // Title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Login Successful!',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF040F1B),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'You will be moved to home screen.\nEnjoy the features!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF4B6164),
                        height: 1.7,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Lets Explore Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onLetsExplore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF040F1B),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF040F1B).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Lets Explore',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
