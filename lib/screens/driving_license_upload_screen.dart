import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/routes/app_routes.dart';
import '../models/driver_registration_data.dart';
import 'selfie_camera_screen.dart';

class DrivingLicenseUploadScreen extends StatefulWidget {
  const DrivingLicenseUploadScreen({super.key});

  @override
  State<DrivingLicenseUploadScreen> createState() => _DrivingLicenseUploadScreenState();
}

enum _LicenseSide { front, back }

class _DrivingLicenseUploadScreenState extends State<DrivingLicenseUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final Map<_LicenseSide, Uint8List?> _photos = {
    _LicenseSide.front: null,
    _LicenseSide.back: null,
  };

  final TextEditingController _licenseNumberController = TextEditingController();
  DateTime? _licenseExpiryDate;

  static const Color _screenBackground = Colors.black;
  static const Color _panelBackground = Color(0xFFFFFFF0);
  static const Color _textPrimary = Color(0xFF111A2B);
  static const Color _textSecondary = Color(0xFF556270);
  static const Color _cardBackground = Color(0xFFE3E3D8);
  static const Color _cardMuted = Color(0xFFD8DACE);
  static const Color _accent = Color(0xFF10B47A);
  static const Color _buttonDark = Color(0xFF001A3A);

  Future<void> _pickLicenseExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _licenseExpiryDate = picked);
  }

  Future<void> _selectPhoto(_LicenseSide side) async {
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
    if (!mounted) return;

    try {
      Uint8List? bytes;
      if (source == ImageSource.camera) {
        bytes = await Navigator.of(context).push<Uint8List>(
          MaterialPageRoute(
            builder: (_) => const SelfieCameraScreen(
              title: 'Capture Driving License',
              preferredLensDirection: CameraLensDirection.back,
              overlayShape: BoxShape.rectangle,
            ),
          ),
        );
      } else {
        final file = await _picker.pickImage(source: source, imageQuality: 80);
        if (file != null) {
          bytes = await file.readAsBytes();
        }
      }

      if (bytes == null || !mounted) return;
      setState(() => _photos[side] = bytes);
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
        SnackBar(content: Text('Please add: ${missing.join(' and ')} side')),
      );
      return;
    }

    if (_licenseNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter license number')),
      );
      return;
    }

    if (_licenseExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select license expiry date')),
      );
      return;
    }

    final data = ModalRoute.of(context)!.settings.arguments as DriverRegistrationData;
    data.driverLicenseNumber = _licenseNumberController.text.trim();
    data.driverLicenseExpiry = '${_licenseExpiryDate!.year}-${_licenseExpiryDate!.month.toString().padLeft(2, '0')}-${_licenseExpiryDate!.day.toString().padLeft(2, '0')}';
    data.driverLicenseFrontBytes = _photos[_LicenseSide.front];
    data.driverLicenseBackBytes = _photos[_LicenseSide.back];

    Navigator.of(context).pushNamed(
      AppRoutes.vehicleInsuranceUpload,
      arguments: data,
    );
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    super.dispose();
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
                    'Driving License',
                    style: TextStyle(
                      fontSize: 21,
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
                  _buildPhotoCard(_LicenseSide.front),
                  const SizedBox(height: 24),
                  _buildPhotoCard(_LicenseSide.back),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'License Number',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _licenseNumberController,
                    style: const TextStyle(fontSize: 17, color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. B1234567',
                      hintStyle: const TextStyle(color: Color(0xFF9AA0AA)),
                      filled: true,
                      fillColor: const Color(0xFFE9E9DC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: _accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'License Expiry Date',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickLicenseExpiry,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9E9DC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _licenseExpiryDate == null
                                ? 'Select expiry date'
                                : '${_licenseExpiryDate!.year}-${_licenseExpiryDate!.month.toString().padLeft(2, '0')}-${_licenseExpiryDate!.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 17,
                              color: _licenseExpiryDate == null ? const Color(0xFF9AA0AA) : _textPrimary,
                            ),
                          ),
                          const Icon(Icons.calendar_today_rounded, color: Color(0xFFB5B6B8), size: 20),
                        ],
                      ),
                    ),
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

  Widget _buildPhotoCard(_LicenseSide side) {
    final image = _photos[side];

    return GestureDetector(
      onTap: () => _selectPhoto(side),
      child: Container(
        width: double.infinity,
        height: 250,
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
                    size: 56,
                    color: Color(0xFFEFEFDF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_labelFor(side)} Side',
                    style: const TextStyle(
                      fontSize: 35 / 2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7E8388),
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(image, fit: BoxFit.cover),
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

  String _labelFor(_LicenseSide side) {
    switch (side) {
      case _LicenseSide.front:
        return 'Front';
      case _LicenseSide.back:
        return 'Back';
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
        color: _DrivingLicenseUploadScreenState._accent,
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

