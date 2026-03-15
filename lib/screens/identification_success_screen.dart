import 'package:flutter/material.dart';

class IdentificationSuccessScreen extends StatelessWidget {
  const IdentificationSuccessScreen({super.key});

  static const Color _screenBackground = Colors.black;
  static const Color _panelBackground = Color(0xFFFFFFF0);
  static const Color _textPrimary = Color(0xFF111A2B);
  static const Color _textSecondary = Color(0xFF5A6475);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _panelBackground,
              borderRadius: BorderRadius.circular(56),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/success.png',
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Verification Successful',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your identification documents have been uploaded successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.45,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

