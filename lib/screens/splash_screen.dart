import 'package:flutter/material.dart';
import 'dart:async';
import '../core/routes/app_routes.dart';
import '../services/token_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Show splash for 3 seconds, then route based on login state
    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final loggedIn = await TokenService.isLoggedIn();
      if (!mounted) return;
      if (loggedIn) {
        // Already authenticated → go straight to home screen
        Navigator.of(context).pushReplacementNamed(AppRoutes.userHomeMap);
      } else {
        // Not logged in → go to Get Started / Login
        Navigator.of(context).pushReplacementNamed(AppRoutes.getStarted);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020D19),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with name image
            Image.asset(
              'assets/images/logo_with_name.png',
              height: 120,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomSheet: Container(
        color: const Color(0xFF020D19),
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '© 2026 RideMate. All Rights Reserved.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
