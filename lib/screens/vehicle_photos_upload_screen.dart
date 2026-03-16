import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VehiclePhotosUploadScreen extends StatefulWidget {
  const VehiclePhotosUploadScreen({super.key});

  @override
  State<VehiclePhotosUploadScreen> createState() => _VehiclePhotosUploadScreenState();
}

enum _VehiclePhotoSide { front, rear, left, right }

class _VehiclePhotosUploadScreenState extends State<VehiclePhotosUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final Map<_VehiclePhotoSide, Uint8List?> _photos = {
    _VehiclePhotoSide.front: null,
    _VehiclePhotoSide.rear: null,
    _VehiclePhotoSide.left: null,
    _VehiclePhotoSide.right: null,
  };

  static const Color _screenBackground = Colors.black;
  static const Color _panelBackground = Color(0xFFFFFFF0);
  static const Color _textPrimary = Color(0xFF111A2B);
  static const Color _textSecondary = Color(0xFF556270);
  static const Color _cardBackground = Color(0xFFE3E3D8);
  static const Color _cardMuted = Color(0xFFD8DACE);
  static const Color _accent = Color(0xFF10B47A);
  static const Color _buttonDark = Color(0xFF001A3A);

  Future<void> _selectPhoto(_VehiclePhotoSide side) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take photo'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Upload from gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();

      if (!mounted) return;
      setState(() {
        _photos[side] = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  void _onNextPressed() {
    final missing = _photos.entries
        .where((entry) => entry.value == null)
        .map((entry) => _labelFor(entry.key))
        .toList();

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add: ${missing.join(', ')}')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vehicle photos uploaded successfully')),
    );
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
              child: Column(
                children: [
                  _buildStepper(),
                  const SizedBox(height: 44),
                  const Text(
                    'Vehicle Photos',
                    style: TextStyle(
                      fontSize: 42 / 2,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please take clear photographs\nof following',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.35,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: _buildPhotoCard(_VehiclePhotoSide.front)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPhotoCard(_VehiclePhotoSide.rear)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildPhotoCard(_VehiclePhotoSide.left)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPhotoCard(_VehiclePhotoSide.right)),
                    ],
                  ),
                  const SizedBox(height: 44),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
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

  Widget _buildStepper() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            children: [
              _StepCircle(number: '1'),
              Expanded(
                child: Divider(
                  color: _accent,
                  thickness: 4,
                  height: 4,
                ),
              ),
              _StepCircle(number: '2'),
            ],
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  'Personal\nDetails',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9EA0A5),
                    height: 1.35,
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  'Vehical\nDetails',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(_VehiclePhotoSide side) {
    final image = _photos[side];
    final label = _labelFor(side);

    return GestureDetector(
      onTap: () => _selectPhoto(side),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: image == null ? _cardMuted : _cardBackground,
          borderRadius: BorderRadius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_rounded,
                    size: 48,
                    color: Color(0xFFEFEFDF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$label Side',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7E8388),
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    image,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        onPressed: () => setState(() => _photos[side] = null),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _labelFor(_VehiclePhotoSide side) {
    switch (side) {
      case _VehiclePhotoSide.front:
        return 'Front';
      case _VehiclePhotoSide.rear:
        return 'Rear';
      case _VehiclePhotoSide.left:
        return 'Left';
      case _VehiclePhotoSide.right:
        return 'Right';
    }
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: const BoxDecoration(
        color: _VehiclePhotosUploadScreenState._accent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

