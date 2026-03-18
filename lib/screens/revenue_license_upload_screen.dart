import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/routes/app_routes.dart';
import '../models/driver_registration_data.dart';
import '../services/driver_service.dart';
import '../services/file_service.dart';
import 'selfie_camera_screen.dart';

class RevenueLicenseUploadScreen extends StatefulWidget {
  const RevenueLicenseUploadScreen({super.key});

  @override
  State<RevenueLicenseUploadScreen> createState() => _RevenueLicenseUploadScreenState();
}

enum _RevenueLicenseSide { front, back }

class _RevenueLicenseUploadScreenState extends State<RevenueLicenseUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final Map<_RevenueLicenseSide, Uint8List?> _photos = {
    _RevenueLicenseSide.front: null,
    _RevenueLicenseSide.back: null,
  };
  bool _isSubmitting = false;

  static const Color _screenBackground = Colors.black;
  static const Color _panelBackground = Color(0xFFFFFFF0);
  static const Color _textPrimary = Color(0xFF111A2B);
  static const Color _textSecondary = Color(0xFF556270);
  static const Color _cardBackground = Color(0xFFE3E3D8);
  static const Color _cardMuted = Color(0xFFD8DACE);
  static const Color _accent = Color(0xFF10B47A);
  static const Color _buttonDark = Color(0xFF001A3A);

  Future<void> _selectPhoto(_RevenueLicenseSide side) async {
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
              title: 'Capture Revenue License',
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

  void _onCompleteRegistrationPressed() {
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
    _submitDriverProfile();
  }

  Future<void> _submitDriverProfile() async {
    final data = ModalRoute.of(context)!.settings.arguments as DriverRegistrationData;
    data.registrationCertificateBytes = _photos[_RevenueLicenseSide.front];
    data.revenueLicenseFrontBytes = _photos[_RevenueLicenseSide.front];
    data.revenueLicenseBackBytes = _photos[_RevenueLicenseSide.back];

    setState(() => _isSubmitting = true);

    try {
      // Upload all documents
      final driverLicenseFrontId = await FileService.uploadFile(
        bytes: data.driverLicenseFrontBytes!,
        fileName: 'driver_license_front.jpg',
      );
      final driverLicenseBackId = await FileService.uploadFile(
        bytes: data.driverLicenseBackBytes!,
        fileName: 'driver_license_back.jpg',
      );
      final vehicleImageId1 = await FileService.uploadFile(
        bytes: data.vehicleImageBytes1!,
        fileName: 'vehicle_image_front.jpg',
      );
      final vehicleImageId2 = await FileService.uploadFile(
        bytes: data.vehicleImageBytes2!,
        fileName: 'vehicle_image_rear.jpg',
      );
      final vehicleImageId3 = await FileService.uploadFile(
        bytes: data.vehicleImageBytes3!,
        fileName: 'vehicle_image_left.jpg',
      );
      final vehicleImageId4 = await FileService.uploadFile(
        bytes: data.vehicleImageBytes4!,
        fileName: 'vehicle_image_right.jpg',
      );
      final registrationCertId = await FileService.uploadFile(
        bytes: data.registrationCertificateBytes!,
        fileName: 'registration_certificate.jpg',
      );
      final insuranceDocId1 = await FileService.uploadFile(
        bytes: data.insuranceDocumentFrontBytes!,
        fileName: 'insurance_document_front.jpg',
      );
      final insuranceDocId2 = await FileService.uploadFile(
        bytes: data.insuranceDocumentBackBytes!,
        fileName: 'insurance_document_back.jpg',
      );
      final revenueLicenseId1 = await FileService.uploadFile(
        bytes: data.revenueLicenseFrontBytes!,
        fileName: 'revenue_license_front.jpg',
      );
      final revenueLicenseId2 = await FileService.uploadFile(
        bytes: data.revenueLicenseBackBytes!,
        fileName: 'revenue_license_back.jpg',
      );

      // Build the request body
      final body = data.toSaveBody(
        driverLicenseFrontDocumentId: driverLicenseFrontId,
        driverLicenseBackDocumentId: driverLicenseBackId,
        vehicleImageDocumentId1: vehicleImageId1,
        vehicleImageDocumentId2: vehicleImageId2,
        vehicleImageDocumentId3: vehicleImageId3,
        vehicleImageDocumentId4: vehicleImageId4,
        registrationCertificateDocumentId: registrationCertId,
        insuranceDocumentId1: insuranceDocId1,
        insuranceDocumentId2: insuranceDocId2,
        revenueLicenseDocumentId1: revenueLicenseId1,
        revenueLicenseDocumentId2: revenueLicenseId2,
      );

      // Save the driver profile
      await DriverService.saveDriverProfile(body: body);

      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.rideStart);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
              child: Column(
                children: [
                  _buildStepper(),
                  const SizedBox(height: 44),
                  const Text(
                    'Revenue License',
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
                  _buildPhotoCard(_RevenueLicenseSide.front),
                  const SizedBox(height: 16),
                  _buildPhotoCard(_RevenueLicenseSide.back),
                  const SizedBox(height: 44),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _onCompleteRegistrationPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Complete Registration',
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

  Widget _buildPhotoCard(_RevenueLicenseSide side) {
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

  String _labelFor(_RevenueLicenseSide side) {
    switch (side) {
      case _RevenueLicenseSide.front:
        return 'Front';
      case _RevenueLicenseSide.back:
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
        color: _RevenueLicenseUploadScreenState._accent,
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

