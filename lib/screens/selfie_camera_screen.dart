import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class SelfieCameraScreen extends StatefulWidget {
  const SelfieCameraScreen({super.key});

  @override
  State<SelfieCameraScreen> createState() => _SelfieCameraScreenState();
}

class _SelfieCameraScreenState extends State<SelfieCameraScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isTakingPhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No camera found on this device.';
          _isInitializing = false;
        });
        return;
      }

      CameraDescription selectedCamera = cameras.first;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to start camera. Check browser camera permission.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPhoto) {
      return;
    }

    setState(() => _isTakingPhoto = true);
    try {
      final photo = await _controller!.takePicture();
      final Uint8List bytes = await photo.readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pop(bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to capture photo. Please try again.'),
        ),
      );
      setState(() => _isTakingPhoto = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Take Selfie'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitializing = true;
                  });
                  _initializeCamera();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller!;
    return Stack(
      children: [
        Positioned.fill(
          child: CameraPreview(controller),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: GestureDetector(
              onTap: _isTakingPhoto ? null : _capturePhoto,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: _isTakingPhoto ? Colors.white54 : Colors.white,
                ),
                child: _isTakingPhoto
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

