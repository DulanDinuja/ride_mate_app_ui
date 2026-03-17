import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/routes/app_routes.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';

class HomeMapScreen extends StatefulWidget {
  final bool showProfilePrompt;

  const HomeMapScreen({
    super.key,
    this.showProfilePrompt = true,
  });

  @override
  State<HomeMapScreen> createState() => HomeMapScreenState();
}

class HomeMapScreenState extends State<HomeMapScreen> {
  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);
  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d1f24"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a8f98"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1d1f24"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#3b3f47"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f7682"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#3a3f48"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#2a2e36"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#525861"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#5f6670"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#474e57"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2d3139"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f2a36"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4d7a8d"}]}
]
''';

  bool _showProfileCard = false;
  bool _isLocating = true;
  String? _locationError;

  GoogleMapController? _mapController;
  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> refreshCurrentLocation() async {
    await _loadCurrentLocation();
  }

  Future<void> _checkProfileStatus() async {
    if (!widget.showProfilePrompt) return;
    try {
      final userId = await TokenService.getUserId();
      if (userId == null) return;
      final profile = await UserService.getUserProfileByUserId(userId);
      if (mounted && !profile.isProfileCompleted) {
        setState(() => _showProfileCard = true);
      }
    } catch (_) {
      if (mounted) setState(() => _showProfileCard = true);
    }
  }

  Future<void> _loadCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied. Please allow location access.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. Enable it from app settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final latLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;

      await _setCurrentLocation(latLng);

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 16),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _setCurrentLocation(LatLng latLng) async {
    if (!mounted) return;
    setState(() => _currentLatLng = latLng);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLatLng != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 16));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentLatLng;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            style: _darkMapStyle,
            initialCameraPosition: CameraPosition(
              target: current ?? _defaultCenter,
              zoom: current == null ? 11 : 16,
            ),
            myLocationEnabled: current != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          _buildLocationButton(),
          if (_isLocating) _buildStatusBanner('Getting your current location...'),
          if (_locationError != null) _buildErrorBanner(_locationError!),
          if (_showProfileCard) _buildCompleteProfileCard(),
        ],
      ),
    );
  }

  Widget _buildLocationButton() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: GestureDetector(
            onTap: _isLocating ? null : refreshCurrentLocation,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF040F1B).withOpacity(0.9),
              ),
              child: _isLocating
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.my_location, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String text) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(message, style: const TextStyle(color: Colors.white))),
              TextButton(
                onPressed: refreshCurrentLocation,
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteProfileCard() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
            decoration: BoxDecoration(
              color: const Color(0xFF040F1B).withOpacity(0.7),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => setState(() => _showProfileCard = false),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: const Icon(Icons.close, color: Colors.white70, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "You're Almost Done! Complete Your Profile To Unlock All Features.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0.75,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade800,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF03AF74)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '75%',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8 * 0.6,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.profileCompletion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03AF74),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Complete Now',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

