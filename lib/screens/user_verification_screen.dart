import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../models/user_verification_args.dart';
import 'selfie_camera_screen.dart';

class UserVerificationScreen extends StatefulWidget {
  const UserVerificationScreen({
    super.key,
    required this.args,
  });

  final UserVerificationArgs args;

  @override
  State<UserVerificationScreen> createState() => _UserVerificationScreenState();
}

class _UserVerificationScreenState extends State<UserVerificationScreen> {
  Uint8List? _capturedSelfie;
  bool _isOpeningCamera = false;

  static const Color _screenBackground = Colors.black;
  static const Color _panelBackground = Color(0xFFFFFFF0);
  static const Color _textPrimary = Color(0xFF111A2B);
  static const Color _textSecondary = Color(0xFF5A6475);
  static const Color _cardBackground = Color(0xFFECEBDD);
  static const Color _accent = Color(0xFF10B47A);

  Future<void> _openSelfieCamera() async {
    if (_isOpeningCamera) return;

    setState(() => _isOpeningCamera = true);
    try {
      final Uint8List? selfieBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => const SelfieCameraScreen(),
        ),
      );

      if (!mounted || selfieBytes == null) {
        return;
      }

      setState(() => _capturedSelfie = selfieBytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open camera: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningCamera = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
              borderRadius: BorderRadius.circular(48),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: _textPrimary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  const Text(
                    'User Verification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Take a clear selfie to complete your verification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.args.documentType} • ${widget.args.gender}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _cardBackground,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Container(
                              color: const Color(0xFFF4F4EA),
                              alignment: Alignment.center,
                              child: _capturedSelfie == null
                                  ? Image.asset(
                                      'assets/images/selfie.png',
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.contain,
                                    )
                                  : Image.memory(
                                      _capturedSelfie!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Center your face inside the frame and make sure your face is clearly visible.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Selfie Guidelines',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Expanded(
                        child: _GuidelineImageItem(
                          imagePath: 'assets/images/correct_selfie.png',
                          label: 'Correct',
                          borderColor: Color(0xFF10B47A),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _GuidelineImageItem(
                          imagePath: 'assets/images/wrong_selfie_1.png',
                          label: 'Wrong',
                          borderColor: Color(0xFFE98989),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _GuidelineImageItem(
                          imagePath: 'assets/images/wrong_selfie_2.png',
                          label: 'Wrong',
                          borderColor: Color(0xFFE98989),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isOpeningCamera ? null : _openSelfieCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isOpeningCamera
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
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
      ),
    );
  }
}

class _GuidelineImageItem extends StatelessWidget {
  const _GuidelineImageItem({
    required this.imagePath,
    required this.label,
    required this.borderColor,
  });

  final String imagePath;
  final String label;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFECEBDD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.55), width: 1.4),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 90,
              color: const Color(0xFFF4F4EA),
              alignment: Alignment.center,
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A6475),
            ),
          ),
        ],
      ),
    );
  }
}

