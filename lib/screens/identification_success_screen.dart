import 'package:flutter/material.dart';

import '../core/routes/app_routes.dart';

class IdentificationSuccessScreen extends StatelessWidget {
  const IdentificationSuccessScreen({super.key});

  static const Color _screenBackground = Colors.black;
  static const Color _panelBackground = Color(0xFFFFFFF0);
  static const Color _textPrimary = Color(0xFF111A2B);
  static const Color _textSecondary = Color(0xFF5A6475);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _panelBackground,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(
              children: [
                // ── Image fills upper portion ──────────────────────────
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/success.png',
                      width: size.width * 0.80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // ── Title ─────────────────────────────────────────────
                const Text(
                  'Successful!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Subtitle ──────────────────────────────────────────
                const Text(
                  'You have successfully completed\nthe user verification.\n'
                  'Your account will be approved\nafter a review process',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // ── Continue button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.homeMap,
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _textPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
