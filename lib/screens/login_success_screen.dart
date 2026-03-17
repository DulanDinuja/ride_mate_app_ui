import 'dart:math';
import 'package:flutter/material.dart';
import '../core/routes/app_routes.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_button.dart';

class LoginSuccessScreen extends StatefulWidget {
  const LoginSuccessScreen({super.key});

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  Future<void> _onLetsExplore() async {
    setState(() => _isLoading = true);
    try {
      final userId = await TokenService.getUserId();
      if (!mounted) return;
      if (userId != null) {
        final profile = await UserService.getUserProfileByUserId(userId);
        if (!mounted) return;
        if (profile.isProfileCompleted) {
          Navigator.pushReplacementNamed(context, AppRoutes.userHomeMap);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.homeMap);
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, AppRoutes.homeMap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFF0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Top Section
            Container(
              height: screenHeight * 0.15,
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

            // Content Container
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 32.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Success Illustration
                    _buildSuccessIllustration(screenWidth),

                    const SizedBox(height: 40),

                    // Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        'Login Successful!',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF040F1B),
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        'You will be moved to home screen right now.\nEnjoy the features!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4B6164),
                          height: 1.7,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Lets Explore Button
                    CustomButton(
                      text: 'Lets Explore',
                      onPressed: _onLetsExplore,
                      isLoading: _isLoading,
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

  Widget _buildSuccessIllustration(double screenWidth) {
    final illustrationSize = screenWidth * 0.75;

    return SizedBox(
      width: illustrationSize,
      height: illustrationSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Large background circle
          Container(
            width: illustrationSize * 0.9,
            height: illustrationSize * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEFFBF2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE7EEFB).withOpacity(0.15),
                  blurRadius: 70,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
          ),

          // Card with shadow
          Positioned(
            top: illustrationSize * 0.2,
            child: Container(
              width: illustrationSize * 0.6,
              height: illustrationSize * 0.68,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFF0),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF636B81).withOpacity(0.15),
                    blurRadius: 100,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  // Dark bar (loading bar placeholder)
                  Container(
                    width: illustrationSize * 0.35,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF040F1B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Light green bar
                  Container(
                    width: illustrationSize * 0.45,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFFBF2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Green checkmark circle
          Positioned(
            top: illustrationSize * 0.18,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: illustrationSize * 0.22,
                height: illustrationSize * 0.22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1A6FCD38), // light green bg
                ),
                child: Center(
                  child: Container(
                    width: illustrationSize * 0.14,
                    height: illustrationSize * 0.14,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF03AF74),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: illustrationSize * 0.08,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Green login icon (top right)
          Positioned(
            top: illustrationSize * 0.08,
            right: illustrationSize * 0.02,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF03AF74),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF636B81).withOpacity(0.25),
                    blurRadius: 60,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.login_rounded,
                color: Color(0xFFFEFEEF),
                size: 22,
              ),
            ),
          ),

          // Decorative elements

          // Small circle top-left area (light)
          Positioned(
            top: illustrationSize * 0.07,
            left: illustrationSize * 0.22,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F3F7),
                border: Border.all(
                  color: const Color(0xFFA0E4D0),
                  width: 2,
                ),
              ),
            ),
          ),

          // Small circle top-left (bordered)
          Positioned(
            top: illustrationSize * 0.04,
            left: illustrationSize * 0.15,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC1CBD4),
                border: Border.all(
                  color: const Color(0xFFA0E4D0),
                  width: 2,
                ),
              ),
            ),
          ),

          // X mark (top-left, green)
          Positioned(
            top: illustrationSize * 0.12,
            left: illustrationSize * 0.06,
            child: Transform.rotate(
              angle: pi / 4,
              child: const Icon(
                Icons.add,
                color: Color(0xFF00AA6C),
                size: 20,
              ),
            ),
          ),

          // X mark (middle-left, blue)
          Positioned(
            top: illustrationSize * 0.58,
            left: illustrationSize * 0.04,
            child: Transform.rotate(
              angle: pi / 4,
              child: const Icon(
                Icons.add,
                color: Color(0xFF85C0F9),
                size: 18,
              ),
            ),
          ),

          // Small dot bottom-left
          Positioned(
            bottom: illustrationSize * 0.1,
            left: illustrationSize * 0.08,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF1F3F7),
              ),
            ),
          ),

          // Small dot (grey, bottom area)
          Positioned(
            bottom: illustrationSize * 0.06,
            left: illustrationSize * 0.35,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFC1CBD4),
              ),
            ),
          ),

          // Small dot top center
          Positioned(
            top: illustrationSize * 0.04,
            left: illustrationSize * 0.32,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFC1CBD4),
              ),
            ),
          ),

          // Green curved line (left side)
          Positioned(
            top: illustrationSize * 0.45,
            left: illustrationSize * 0.0,
            child: CustomPaint(
              size: const Size(40, 45),
              painter: _CurvedLinePainter(
                color: const Color(0xFF00D098),
                strokeWidth: 3.5,
              ),
            ),
          ),

          // Teal arc (top center-right)
          Positioned(
            top: illustrationSize * 0.01,
            right: illustrationSize * 0.15,
            child: CustomPaint(
              size: const Size(35, 30),
              painter: _ArcPainter(
                color: const Color(0xFFA0E4D0),
                strokeWidth: 3.5,
              ),
            ),
          ),

          // Orange curved line (right side)
          Positioned(
            bottom: illustrationSize * 0.12,
            right: illustrationSize * 0.02,
            child: CustomPaint(
              size: const Size(35, 30),
              painter: _OrangeCurvePainter(
                color: const Color(0xFFF39958),
                strokeWidth: 3.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the green S-curve on the left
class _CurvedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _CurvedLinePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.8, 0);
    path.cubicTo(
      size.width * 0.2, size.height * 0.3,
      size.width * 1.0, size.height * 0.6,
      size.width * 0.3, size.height,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for the teal arc at the top
class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.5, -size.height * 0.5,
      size.width, size.height * 0.8,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for the orange curve on the right
class _OrangeCurvePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _OrangeCurvePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, 0);
    path.cubicTo(
      size.width * 0.8, size.height * 0.2,
      size.width * 0.3, size.height * 0.9,
      size.width, size.height,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

