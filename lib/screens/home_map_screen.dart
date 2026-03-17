import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/routes/app_routes.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';

class HomeMapScreen extends StatefulWidget {
  final bool showProfilePrompt;
  final bool showMenuButton;

  const HomeMapScreen({
    super.key,
    this.showProfilePrompt = true,
    this.showMenuButton = true,
  });

  @override
  State<HomeMapScreen> createState() => HomeMapScreenState();
}

class HomeMapScreenState extends State<HomeMapScreen> {
  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);
  static const double _bottomCardSpace = 255;
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
  bool _isSearchingDrop = false;
  String? _locationError;
  String _pickupAddress = 'Detecting current location...';
  String _dropAddress = 'Choose drop location by map tap or search.';

  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;

  final TextEditingController _dropSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _dropSearchController.dispose();
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

      await _setPickupLocation(latLng);

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

  Future<void> _setPickupLocation(LatLng latLng) async {
    final readable = await _resolveAddress(latLng);
    if (!mounted) return;

    setState(() {
      _currentLatLng = latLng;
      _pickupLatLng = latLng;
      _pickupAddress = readable;
    });
  }

  Future<void> _setDropLocation(LatLng latLng, {String? knownAddress}) async {
    final readable = knownAddress ?? await _resolveAddress(latLng);
    if (!mounted) return;

    setState(() {
      _dropLatLng = latLng;
      _dropAddress = readable;
      _dropSearchController.text = readable;
    });

    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 16),
      );
    }
  }

  Future<void> _searchDropLocation(String query) async {
    final input = query.trim();
    if (input.isEmpty) return;

    setState(() => _isSearchingDrop = true);
    try {
      final locations = await locationFromAddress(input);
      if (locations.isEmpty) {
        throw Exception('No location found for "$input".');
      }

      final first = locations.first;
      await _setDropLocation(
        LatLng(first.latitude, first.longitude),
        knownAddress: input,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Drop search failed: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSearchingDrop = false);
      }
    }
  }

  Future<String> _resolveAddress(LatLng latLng) async {
    try {
      final places = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (places.isEmpty) {
        return '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
      }

      final p = places.first;
      final parts = <String>[
        if ((p.name ?? '').trim().isNotEmpty) p.name!.trim(),
        if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
        if ((p.administrativeArea ?? '').trim().isNotEmpty) p.administrativeArea!.trim(),
      ];
      if (parts.isEmpty) {
        return '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
      }
      return parts.join(', ');
    } catch (_) {
      return '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLatLng != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 16));
    }
  }

  void _onMenuPressed() {
    // Placeholder for future drawer/menu action.
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentLatLng;
    final markers = <Marker>{
      if (_pickupLatLng != null)
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: _pickupLatLng!,
          infoWindow: const InfoWindow(title: 'Pickup location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      if (_dropLatLng != null)
        Marker(
          markerId: const MarkerId('drop_location'),
          position: _dropLatLng!,
          infoWindow: const InfoWindow(title: 'Drop location'),
        ),
    };

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onTap: _setDropLocation,
            style: _darkMapStyle,
            initialCameraPosition: CameraPosition(
              target: current ?? _defaultCenter,
              zoom: current == null ? 11 : 16,
            ),
            myLocationEnabled: current != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
          ),
          _buildTopPanel(),
          _buildConfirmButton(),
          if (_isLocating) _buildStatusBanner('Getting your current location...'),
          if (_locationError != null) _buildErrorBanner(_locationError!),
          if (_showProfileCard) _buildCompleteProfileCard(),
        ],
      ),
    );
  }

  Widget _buildTopPanel() {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = scheme.outline.withOpacity(0.35);
    final inputColor = scheme.surfaceContainerHighest.withOpacity(0.75);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: scheme.surface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: const [
                  BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Menu row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
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
                      if (widget.showMenuButton)
                        GestureDetector(
                          onTap: _onMenuPressed,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF040F1B).withOpacity(0.9),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildMenuLine(),
                                const SizedBox(height: 4),
                                _buildMenuLine(),
                                const SizedBox(height: 4),
                                _buildMenuLine(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Pickup row
                  _buildLocationRow(
                    icon: Icons.my_location,
                    iconColor: const Color(0xFF03AF74),
                    label: 'Pickup',
                    value: _pickupAddress,
                    trailing: IconButton(
                      icon: Icon(Icons.gps_fixed, color: scheme.primary, size: 20),
                      onPressed: _isLocating ? null : refreshCurrentLocation,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Drop search field
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 2, 8, 2),
                    decoration: BoxDecoration(
                      color: inputColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _dropSearchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchDropLocation,
                      style: TextStyle(color: scheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Drop location',
                        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                        hintText: 'Search destination',
                        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.7)),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.location_on, color: scheme.error),
                        suffixIcon: _isSearchingDrop
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                onPressed: () => _searchDropLocation(_dropSearchController.text),
                                icon: Icon(Icons.search, color: scheme.primary),
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

  Widget _buildStatusBanner(String text) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: _bottomCardSpace),
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
          margin: const EdgeInsets.only(bottom: _bottomCardSpace),
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
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

  Widget _buildConfirmButton() {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_pickupLatLng != null && _dropLatLng != null) ? _onConfirmPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF03AF74),
                disabledBackgroundColor: const Color(0xFF03AF74).withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onConfirmPressed() {
    // TODO: Navigate or proceed with pickup & drop locations
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withOpacity(0.35)),
      ),
      child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withOpacity(0.14),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    ));
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

  Widget _buildMenuLine() {
    return Container(
      width: 22,
      height: 3,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFF0),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

