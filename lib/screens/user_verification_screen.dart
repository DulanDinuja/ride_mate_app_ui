import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../core/routes/app_routes.dart';
import '../models/user_verification_args.dart';
import '../services/file_service.dart';
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
  bool _isUploading = false;

  static const Color _screenBackground = Colors.black;
  static const Color _panelBackground = Color(0xFFFFFFF0);
  static const Color _textPrimary = Color(0xFF111A2B);
  static const Color _textSecondary = Color(0xFF5A6475);
  static const Color _cardBackground = Color(0xFFECEBDD);
  static const Color _accent = Color(0xFF10B47A);

  Future<void> _uploadSelfie() async {
    if (_capturedSelfie == null || _isUploading) return;

    setState(() => _isUploading = true);
    try {
      await FileService.uploadFile(
        bytes: _capturedSelfie!,
        fileName: 'selfie.jpg',
      );

      if (!mounted) return;
      Navigator.of(context).pushNamed(
        AppRoutes.identificationDocument,
        arguments: widget.args,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
            child: _capturedSelfie == null
                ? _buildVerificationView(context)
                : _buildSelfiePreviewView(context),
          ),
        ),
      ),
    );
  }

  // ── Before selfie ──────────────────────────────────────────────────────────
  Widget _buildVerificationView(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SingleChildScrollView(
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
          // Selfie placeholder card
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
                      child: Image.asset(
                        'assets/images/selfie.png',
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
          // Take a Selfie button
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _isOpeningCamera ? null : _openSelfieCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
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
                      'Take a Selfie',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── After selfie ───────────────────────────────────────────────────────────
  Widget _buildSelfiePreviewView(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => setState(() => _capturedSelfie = null),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: _textPrimary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          SizedBox(height: size.height * 0.02),
          const Text(
            'Selfie Preview',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please follow the instructions at the bottom of the screen in the next page to verify yourself.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: _textSecondary,
            ),
          ),
          SizedBox(height: size.height * 0.04),
          // Circular selfie frame
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.25),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Container(
              width: size.width * 0.68,
              height: size.width * 0.68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _accent, width: 4),
                color: const Color(0xFFECEBDD),
              ),
              child: ClipOval(
                child: Image.memory(
                  _capturedSelfie!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(height: size.height * 0.03),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _accent.withOpacity(0.4), width: 1.2),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: _accent, size: 18),
                SizedBox(width: 6),
                Text(
                  'Selfie Captured',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Retake button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _isOpeningCamera ? null : _openSelfieCamera,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text(
                'Take Again',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.black, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadSelfie,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Continue To Next Step',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
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
