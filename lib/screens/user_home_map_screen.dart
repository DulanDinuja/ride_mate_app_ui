import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../core/routes/app_routes.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/driver_service.dart';
import '../services/file_service.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';

class UserHomeMapScreen extends StatefulWidget {
  const UserHomeMapScreen({super.key});

  @override
  State<UserHomeMapScreen> createState() => _UserHomeMapScreenState();
}

class _UserHomeMapScreenState extends State<UserHomeMapScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  // ── bottom nav ──
  int _selectedIndex = 3;

  // ── profile ──
  bool _isLoadingProfile = true;
  bool _isUploadingPhoto = false;
  bool _showDriverProfileCard = false;
  String? _loadError;
  UserProfile? _userProfile;

  // ── map / ride ──
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

  GoogleMapController? _mapController;
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  String _pickupAddress = 'Detecting current location...';
  String _dropAddress = '';
  bool _isLocating = true;
  bool _isSearchingDrop = false;
  String? _locationError;
  final TextEditingController _dropController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _dropController.dispose();
    super.dispose();
  }

  // ── location ──────────────────────────────────────────────────────

  Future<void> _loadCurrentLocation() async {
    if (!mounted) return;
    setState(() { _isLocating = true; _locationError = null; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services disabled. Please enable GPS.');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      final address = await _resolveAddress(latLng);
      if (!mounted) return;
      setState(() {
        _pickupLatLng = latLng;
        _pickupAddress = address;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<String> _resolveAddress(LatLng latLng) async {
    try {
      final places = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (places.isEmpty) return _coordString(latLng);
      final p = places.first;
      final parts = [
        if ((p.name ?? '').trim().isNotEmpty) p.name!.trim(),
        if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
        if ((p.administrativeArea ?? '').trim().isNotEmpty) p.administrativeArea!.trim(),
      ];
      return parts.isEmpty ? _coordString(latLng) : parts.join(', ');
    } catch (_) {
      return _coordString(latLng);
    }
  }

  String _coordString(LatLng l) =>
      '${l.latitude.toStringAsFixed(5)}, ${l.longitude.toStringAsFixed(5)}';

  Future<void> _searchDrop(String query) async {
    final input = query.trim();
    if (input.isEmpty) return;
    setState(() => _isSearchingDrop = true);
    try {
      final locations = await locationFromAddress(input);
      if (locations.isEmpty) throw Exception('No location found for "$input".');
      final latLng = LatLng(locations.first.latitude, locations.first.longitude);
      if (!mounted) return;
      setState(() {
        _dropLatLng = latLng;
        _dropAddress = input;
        _dropController.text = input;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red.shade700,
      ));
    } finally {
      if (mounted) setState(() => _isSearchingDrop = false);
    }
  }

  Future<void> _onMapTap(LatLng latLng) async {
    final address = await _resolveAddress(latLng);
    if (!mounted) return;
    setState(() {
      _dropLatLng = latLng;
      _dropAddress = address;
      _dropController.text = address;
    });
  }

  void _onConfirm() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Ride confirmed! Looking for drivers...'),
      backgroundColor: Color(0xFF03AF74),
    ));
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _loadError = null;
    });

    try {
      final userId = await TokenService.getUserId();
      if (userId == null) {
        throw Exception('Missing user id. Please login again.');
      }

      final profile = await UserService.getUserProfileByUserId(userId);
      if (!mounted) return;

      setState(() {
        _userProfile = profile;
      });

      // Check driver profile if user is willing to drive
      if (profile.isProfileCompleted && profile.isWillingToDrive) {
        await _checkDriverProfileStatus(userId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _checkDriverProfileStatus(String userId) async {
    try {
      final driverProfile =
          await DriverService.getDriverProfileByUserId(userId);
      if (mounted && !driverProfile.isDriverProfileCompleted) {
        setState(() => _showDriverProfileCard = true);
      }
    } catch (_) {
      // Driver profile not found (non-200) — show popup
      if (mounted) {
        setState(() => _showDriverProfileCard = true);
      }
    }
  }

  Future<void> _onChangeProfilePhoto() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (file == null || !mounted) return;

      setState(() => _isUploadingPhoto = true);

      final bytes = await file.readAsBytes();
      final fileName = file.name.isNotEmpty ? file.name : file.path.split('/').last;
      final documentId = await FileService.uploadFile(bytes: bytes, fileName: fileName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile photo uploaded successfully (id: $documentId).'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo upload failed: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _onLogout() async {
    await AuthService.logout();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  void _showComingSoon(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$featureName is coming soon.')),
    );
  }

  String _safeValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Not set' : trimmed;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildAccountTab() {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _userProfile;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (profile != null)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF03AF74),
                    backgroundImage: (profile.userVerificationImageUrl ?? '').isNotEmpty
                        ? NetworkImage(profile.userVerificationImageUrl!)
                        : null,
                    child: (profile.userVerificationImageUrl ?? '').isNotEmpty
                        ? null
                        : const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile.firstName} ${profile.lastName}'.trim(),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(profile.email, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        _buildSectionTitle('Account Details'),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Phone Number'),
                subtitle: Text(profile == null ? 'Not available' : _safeValue(profile.phoneNumber)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Role'),
                subtitle: Text(profile == null ? 'Not available' : _safeValue(profile.role)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Account Status'),
                subtitle: Text(profile == null ? 'Not available' : _safeValue(profile.status)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Date of Birth'),
                subtitle: Text(profile == null ? 'Not available' : _safeValue(profile.dateOfBirth)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Gender'),
                subtitle: Text(profile == null ? 'Not available' : _safeValue(profile.gender)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Preferred Language'),
                subtitle: Text(profile == null ? 'Not available' : _safeValue(profile.preferredLanguage)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionTitle('Profile & Security'),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Update Profile Details'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.profileCompletion),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Reset Password'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Change Profile Photo'),
                trailing: _isUploadingPhoto
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _isUploadingPhoto ? null : _onChangeProfilePhoto,
              ),
              const Divider(height: 1),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionTitle('Preferences & Support'),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Notification Settings'),
                onTap: () {
                  setState(() => _selectedIndex = 1);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.tune_outlined),
                title: const Text('Ride Preferences'),
                onTap: () => _showComingSoon('Ride preferences'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () => _showComingSoon('Help & support'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy & Terms'),
                onTap: () => _showComingSoon('Privacy & terms'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: _onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    return const Center(
      child: Text(
        'No notifications yet',
        style: TextStyle(fontSize: 16, color: Colors.black54),
      ),
    );
  }

  Widget _buildActiveRidesTab() {
    return const Center(
      child: Text(
        'No active rides right now',
        style: TextStyle(fontSize: 16, color: Colors.black54),
      ),
    );
  }

  String _titleForTab() {
    switch (_selectedIndex) {
      case 0:
        return 'Account';
      case 1:
        return 'Notifications';
      case 2:
        return 'Active Rides';
      default:
        return 'Home';
    }
  }

  // ── map tab ───────────────────────────────────────────────────────

  Widget _buildMapTab() {
    final markers = <Marker>{
      if (_pickupLatLng != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      if (_dropLatLng != null)
        Marker(
          markerId: const MarkerId('drop'),
          position: _dropLatLng!,
          infoWindow: const InfoWindow(title: 'Drop'),
        ),
    };

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) {
              _mapController = c;
              if (_pickupLatLng != null) {
                c.animateCamera(CameraUpdate.newLatLngZoom(_pickupLatLng!, 16));
              }
            },
            onTap: _onMapTap,
            style: _darkMapStyle,
            initialCameraPosition: CameraPosition(
              target: _pickupLatLng ?? _defaultCenter,
              zoom: _pickupLatLng == null ? 11 : 16,
            ),
            myLocationEnabled: _pickupLatLng != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
          ),
          _buildRidePanel(),
          if (_isLocating)
            _buildBanner('Getting your current location...', Colors.black87),
          if (!_isLocating && _locationError != null)
            _buildErrorBanner(_locationError!),
          if (_showDriverProfileCard) _buildCompleteDriverProfileCard(),
        ],
      ),
    );
  }

  Widget _buildRidePanel() {
    final scheme = Theme.of(context).colorScheme;
    final border = scheme.outline.withOpacity(0.3);
    final fill = scheme.surfaceContainerHighest.withOpacity(0.75);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── top card: pickup + drop ──
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: BoxDecoration(
                    color: scheme.surface.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                    boxShadow: const [
                      BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // GPS refresh button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: _isLocating ? null : _loadCurrentLocation,
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF040F1B).withOpacity(0.9),
                            ),
                            child: _isLocating
                                ? const Padding(
                                    padding: EdgeInsets.all(9),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.my_location, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Pickup row
                      _buildLocationRow(
                        icon: Icons.my_location,
                        iconColor: const Color(0xFF03AF74),
                        label: 'Pickup',
                        value: _pickupAddress,
                        scheme: scheme,
                      ),
                      const SizedBox(height: 8),
                      // Drop search field
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 2, 8, 2),
                        decoration: BoxDecoration(
                          color: fill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: TextField(
                          controller: _dropController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: _searchDrop,
                          style: TextStyle(color: scheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Drop location',
                            labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                            hintText: 'Search or tap map',
                            hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.7)),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.location_on, color: scheme.error),
                            suffixIcon: _isSearchingDrop
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2)),
                                  )
                                : IconButton(
                                    icon: Icon(Icons.search, color: scheme.primary),
                                    onPressed: () => _searchDrop(_dropController.text),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── confirm button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_pickupLatLng != null && _dropLatLng != null) ? _onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03AF74),
                  disabledBackgroundColor: const Color(0xFF03AF74).withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Confirm Ride',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required ColorScheme scheme,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withOpacity(0.14),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(String text, Color bg) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 80),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 80),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(message, style: const TextStyle(color: Colors.white))),
            TextButton(
              onPressed: _loadCurrentLocation,
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteDriverProfileCard() {
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
                    onTap: () async {
                      setState(() => _showDriverProfileCard = false);
                      try {
                        final userId = await TokenService.getUserId();
                        if (userId != null) {
                          await UserService.updateWillingToDrive(userId, 'NO');
                        }
                      } catch (_) {
                        // Best-effort — popup is already dismissed
                      }
                    },
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
                  'Complete Driver Profile',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please complete your driver profile to start accepting rides.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8 * 0.6,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _showDriverProfileCard = false);
                      Navigator.pushNamed(context, AppRoutes.vehicleRegistration);
                    },
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

  // ── build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildAccountTab(),
      _buildNotificationsTab(),
      _buildActiveRidesTab(),
      _buildMapTab(),
    ];

    return Scaffold(
      appBar: _selectedIndex == 3
          ? null
          : AppBar(
              title: Text(_titleForTab()),
              backgroundColor: const Color(0xFF040F1B),
              foregroundColor: Colors.white,
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 3 && _pickupLatLng != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(_pickupLatLng!, 16),
            );
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_taxi_outlined),
            selectedIcon: Icon(Icons.local_taxi),
            label: 'Active Rides',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
        ],
      ),
    );
  }
}

