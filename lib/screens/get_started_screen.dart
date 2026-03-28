import 'package:flutter/material.dart';
import 'login_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF020808),
      body: Column(
        children: [
          // ── Top: full background image ──────────────────────────────
          Stack(
            children: [
              Image.asset(
                'assets/images/getstart_background.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
              // Bottom fade into dark section
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: screenHeight * 0.15,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xFF020808)],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom: logo + button + login ──────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFF020808),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Full logo with name
                  SizedBox(
                    height: 80,
                    child: Image.asset(
                      'assets/images/logo_with_name.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // GET STARTED button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, a, __) => const LoginScreen(),
                            transitionsBuilder: (_, animation, __, child) {
                              final slide = Tween(
                                begin: const Offset(0.0, 1.0),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeOutCubic));
                              final fade = CurvedAnimation(
                                parent: animation,
                                curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
                              );
                              return FadeTransition(
                                opacity: fade,
                                child: SlideTransition(
                                  position: animation.drive(slide),
                                  child: child,
                                ),
                              );
                            },
                            transitionDuration: const Duration(milliseconds: 550),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'GET STARTED',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Already have an account? Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, a, __) => const LoginScreen(),
                              transitionsBuilder: (_, animation, __, child) {
                                final slide = Tween(
                                  begin: const Offset(0.0, 1.0),
                                  end: Offset.zero,
                                ).chain(CurveTween(curve: Curves.easeOutCubic));
                                final fade = CurvedAnimation(
                                  parent: animation,
                                  curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
                                );
                                return FadeTransition(
                                  opacity: fade,
                                  child: SlideTransition(
                                    position: animation.drive(slide),
                                    child: child,
                                  ),
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 550),
                            ),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
