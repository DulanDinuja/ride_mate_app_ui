import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

// ignore_for_file: unused_element

import '../core/routes/app_routes.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';

class DriverHomeMapScreen extends StatefulWidget {
  const DriverHomeMapScreen({super.key});

  @override
  State<DriverHomeMapScreen> createState() => _DriverHomeMapScreenState();
}

class _DriverHomeMapScreenState extends State<DriverHomeMapScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  int _selectedIndex = 3;

  bool _isLoadingProfile = true;
  bool _isUploadingPhoto = false;
  bool _isChangingRole = false;
  String? _loadError;
  UserProfile? _userProfile;

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
  LatLng? _currentLatLng;
  String _currentAddress = 'Detecting current location...';
  bool _isLocating = true;
  String? _locationError;

  // ── route ──
  Set<Polyline> _polylines = {};
  double? _routeDistanceKm;
  String? _routeDuration;
  bool _isFetchingRoute = false;

  // ── destination ──
  LatLng? _destLatLng;
  String _destAddress = '';
  bool _isSearchingDest = false;

  // ── search overlay ──
  bool _isSearchMode = false;
  bool _isSearchingPlaces = false;
  Timer? _searchDebounceTimer;
  List<Map<String, dynamic>> _placePredictions = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, String>> _recentSearches = [];

  // Driver availability toggle
  bool _isAvailable = false;

  // Available seats & note
  int _availableSeats = 1;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _noteController.dispose();
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
      if (!mounted) return;
      setState(() {
        _currentLatLng = latLng;
        _currentAddress = 'Current Location';
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      final address = await _resolveAddress(latLng);
      if (mounted) setState(() => _currentAddress = address);
    } catch (e) {
      if (mounted) setState(() => _locationError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  static const String _gMapsKey = 'AIzaSyAaIKIFaESxfhuchdlrRRQh7r6y9UhU9Uo';

  Future<String> _resolveAddress(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];
        if ((p.subLocality ?? '').isNotEmpty) parts.add(p.subLocality!);
        else if ((p.thoroughfare ?? '').isNotEmpty) parts.add(p.thoroughfare!);
        if ((p.locality ?? '').isNotEmpty && !parts.contains(p.locality)) parts.add(p.locality!);
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (_) {}

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${latLng.latitude}&lon=${latLng.longitude}'
        '&format=json&zoom=16&addressdetails=1',
      );
      final resp = await http.get(url, headers: {'User-Agent': 'RideMateApp/1.0', 'Accept-Language': 'en'});
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final suburb = addr['suburb'] as String?;
          final city = addr['city'] as String? ?? addr['town'] as String?;
          if (suburb != null && city != null) return '$suburb, $city';
          if (city != null) return city;
          if (suburb != null) return suburb;
        }
      }
    } catch (_) {}

    return '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
  }

  void _onStartRide() {
    if (_destLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please set a destination first.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Looking for ride requests...'),
      backgroundColor: Color(0xFF03AF74),
    ));
  }

  // ── search helpers ──

  void _openSearchMode() {
    setState(() {
      _isSearchMode = true;
      _searchController.clear();
      _placePredictions = [];
      _destLatLng = null;
      _destAddress = '';
      _polylines = {};
      _routeDistanceKm = null;
      _routeDuration = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocusNode.requestFocus());
  }

  void _closeSearchMode() {
    _searchDebounceTimer?.cancel();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearchMode = false;
      _placePredictions = [];
      _isSearchingPlaces = false;
      _searchController.clear();
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() { _placePredictions = []; _isSearchingPlaces = false; });
      return;
    }
    setState(() => _isSearchingPlaces = true);
    _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () => _fetchPlacePredictions(trimmed));
  }

  Future<void> _fetchPlacePredictions(String input) async {
    try {
      final loc = _currentLatLng ?? _defaultCenter;
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=$_gMapsKey'
        '&components=country:lk'
        '&location=${loc.latitude},${loc.longitude}'
        '&radius=50000',
      );
      final resp = await http.get(url);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['status'] == 'OK') {
          setState(() {
            _placePredictions = (data['predictions'] as List).map<Map<String, dynamic>>((p) => {
              'place_id': p['place_id'] ?? '',
              'description': p['description'] ?? '',
              'main_text': (p['structured_formatting']?['main_text'] ?? p['description'] ?? '') as String,
              'secondary_text': (p['structured_formatting']?['secondary_text'] ?? '') as String,
              'source': 'google',
            }).toList();
            _isSearchingPlaces = false;
          });
          return;
        }
      }
    } catch (e) { debugPrint('[Places] Google error: $e'); }

    try {
      final loc = _currentLatLng ?? _defaultCenter;
      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(input)}&limit=10&lang=en'
        '&lat=${loc.latitude}&lon=${loc.longitude}',
      );
      final resp = await http.get(url);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final features = (json.decode(resp.body)['features'] as List?) ?? [];
        final lk = features.where((f) =>
          ((f['properties'] as Map?)?['country'] as String? ?? '').toLowerCase().contains('sri lanka')
        ).toList();
        final results = lk.isNotEmpty ? lk : features;
        setState(() {
          _placePredictions = results.take(7).map<Map<String, dynamic>>((f) {
            final props = f['properties'] as Map<String, dynamic>? ?? {};
            final coords = (f['geometry']?['coordinates'] as List?) ?? [0.0, 0.0];
            final mainText = (props['name'] ?? '') as String;
            final secondary = <String>[];
            for (final k in ['city', 'county', 'state', 'country']) {
              final v = props[k] as String?;
              if (v != null && v.isNotEmpty && v != mainText) secondary.add(v);
            }
            return {
              'place_id': '', 'description': '$mainText, ${secondary.join(', ')}',
              'main_text': mainText, 'secondary_text': secondary.join(', '),
              'source': 'photon',
              'lat': (coords[1] as num).toDouble(),
              'lon': (coords[0] as num).toDouble(),
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('[Places] Photon error: $e');
      if (mounted) setState(() => _placePredictions = []);
    } finally {
      if (mounted) setState(() => _isSearchingPlaces = false);
    }
  }

  Future<void> _selectPrediction(Map<String, dynamic> prediction) async {
    final source = prediction['source'] as String? ?? 'google';
    final mainText = prediction['main_text'] as String;
    final description = prediction['description'] as String;
    _closeSearchMode();
    setState(() => _isSearchingDest = true);
    try {
      LatLng latLng;
      if (source == 'photon' || source == 'nominatim') {
        latLng = LatLng((prediction['lat'] as num).toDouble(), (prediction['lon'] as num).toDouble());
      } else {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=${prediction['place_id']}&key=$_gMapsKey&fields=geometry',
        );
        final resp = await http.get(url);
        if (!mounted) return;
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          if (data['status'] == 'OK') {
            final loc = data['result']['geometry']['location'];
            latLng = LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
          } else { throw Exception('Could not resolve location.'); }
        } else { throw Exception('Could not resolve location.'); }
      }
      if (!mounted) return;
      setState(() { _destLatLng = latLng; _destAddress = mainText; });
      _fetchRoute();
      _recentSearches.removeWhere((r) => r['name'] == mainText);
      _recentSearches.insert(0, {
        'name': mainText, 'address': description,
        'place_id': prediction['place_id']?.toString() ?? '',
        'lat': latLng.latitude.toString(), 'lon': latLng.longitude.toString(),
        'source': source,
      });
      if (_recentSearches.length > 5) _recentSearches = _recentSearches.sublist(0, 5);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red.shade700,
      ));
    } finally {
      if (mounted) setState(() => _isSearchingDest = false);
    }
  }

  void _selectRecentSearch(Map<String, String> recent) {
    final lat = double.tryParse(recent['lat'] ?? '');
    final lon = double.tryParse(recent['lon'] ?? '');
    if (lat != null && lon != null) {
      _selectPrediction({
        'place_id': recent['place_id'] ?? '',
        'main_text': recent['name'] ?? '',
        'description': recent['address'] ?? '',
        'source': recent['source'] ?? 'nominatim',
        'lat': lat, 'lon': lon,
      });
    } else {
      _closeSearchMode();
    }
  }

  Future<void> _fetchRoute() async {
    final origin = _currentLatLng;
    final destination = _destLatLng;
    if (origin == null || destination == null) return;
    setState(() { _isFetchingRoute = true; _polylines = {}; _routeDistanceKm = null; _routeDuration = null; });
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$_gMapsKey',
      );
      final resp = await http.get(url);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final distanceM = (leg['distance']['value'] as num).toDouble();
          final durationText = leg['duration']['text'] as String;
          final points = _decodePolyline(route['overview_polyline']['points'] as String);
          final bounds = _boundsFromLatLngs([origin, destination, ...points]);
          _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
          setState(() {
            _routeDistanceKm = distanceM / 1000;
            _routeDuration = durationText;
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: const Color(0xFF03AF74),
                width: 5,
              ),
            };
          });
          return;
        }
      }
    } catch (e) { debugPrint('[Route] $e'); }
    if (mounted) {
      final distM = Geolocator.distanceBetween(
        origin.latitude, origin.longitude, destination.latitude, destination.longitude,
      );
      setState(() {
        _routeDistanceKm = distM / 1000;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [origin, destination],
            color: const Color(0xFF03AF74),
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        };
      });
    }
    if (mounted) setState(() => _isFetchingRoute = false);
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0; result = 0;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  LatLngBounds _boundsFromLatLngs(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }

  // ── profile ──────────────────────────────────────────────────────

  Future<void> _loadUserProfile() async {
    setState(() { _isLoadingProfile = true; _loadError = null; });
    try {
      final userId = await TokenService.getUserId();
      if (userId == null) throw Exception('Missing user id. Please login again.');
      final profile = await UserService.getUserProfileByUserId(userId);
      if (mounted) setState(() => _userProfile = profile);
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _onChangeRole() async {
    final profile = _userProfile;
    if (profile == null) return;
    final userId = await TokenService.getUserId();
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch to Passenger?'),
        content: const Text('Switch your role back to Passenger?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isChangingRole = true);
    try {
      await UserService.updateRole(userId, 'PASSENGER');
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.userHomeMap, (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _isChangingRole = false);
    }
  }

  Future<void> _onChangeProfilePhoto() async {
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null || !mounted) return;
      setState(() => _isUploadingPhoto = true);
      final bytes = await file.readAsBytes();
      final fileName = file.name.isNotEmpty ? file.name : file.path.split('/').last;
      await FileService.uploadFile(bytes: bytes, fileName: fileName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo upload failed: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _onLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  void _showComingSoon(String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name is coming soon.')));
  }

  String _safeValue(String value) {
    final t = value.trim();
    return t.isEmpty ? 'Not set' : t;
  }

  // ── tabs ──────────────────────────────────────────────────────────

  Widget _buildAccountTab() {
    if (_isLoadingProfile) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadUserProfile, child: const Text('Retry')),
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
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF03AF74).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'DRIVER',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF03AF74)),
                          ),
                        ),
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
                subtitle: const Text('DRIVER'),
                trailing: _isChangingRole
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch(
                        value: true,
                        activeColor: const Color(0xFF03AF74),
                        onChanged: _isChangingRole ? null : (_) => _onChangeRole(),
                      ),
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
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
                onTap: _isUploadingPhoto ? null : _onChangeProfilePhoto,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionTitle('Support'),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () => _showComingSoon('Help & support'),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black54)),
    );
  }

  Widget _buildNotificationsTab() {
    return const Center(child: Text('No notifications yet', style: TextStyle(fontSize: 16, color: Colors.black54)));
  }

  Widget _buildActiveRidesTab() {
    return const Center(child: Text('No active rides right now', style: TextStyle(fontSize: 16, color: Colors.black54)));
  }

  String _titleForTab() {
    switch (_selectedIndex) {
      case 0: return 'Account';
      case 1: return 'Notifications';
      case 2: return 'Active Rides';
      default: return 'Home';
    }
  }

  // ── map tab ───────────────────────────────────────────────────────

  Widget _buildMapTab() {
    final markers = <Marker>{
      if (_currentLatLng != null)
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLatLng!,
          infoWindow: const InfoWindow(title: 'Start Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      if (_destLatLng != null)
        Marker(
          markerId: const MarkerId('dest'),
          position: _destLatLng!,
          infoWindow: const InfoWindow(title: 'End Location'),
        ),
    };

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) {
              _mapController = c;
              c.setMapStyle(_darkMapStyle).catchError((_) {});
              if (_currentLatLng != null) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted && _currentLatLng != null) {
                    c.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 16));
                  }
                });
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentLatLng ?? _defaultCenter,
              zoom: _currentLatLng == null ? 11 : 16,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
            polylines: _polylines,
          ),
          _buildDriverPanel(),
          if (_isLocating)
            _buildBanner('Getting your current location...', Colors.black87),
          if (!_isLocating && _locationError != null)
            _buildErrorBanner(_locationError!),
          if (_isSearchMode) _buildSearchOverlay(),
        ],
      ),
    );
  }

  Widget _buildDriverPanel() {
    final scheme = Theme.of(context).colorScheme;
    final border = scheme.outline.withOpacity(0.3);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
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
                      // GPS refresh + availability row
                      Row(
                        children: [
                          GestureDetector(
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
                          const Spacer(),
                          // Availability toggle
                          GestureDetector(
                            onTap: () => setState(() => _isAvailable = !_isAvailable),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: _isAvailable
                                    ? const Color(0xFF03AF74).withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isAvailable ? const Color(0xFF03AF74) : Colors.grey.shade400,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isAvailable ? const Color(0xFF03AF74) : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isAvailable ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _isAvailable ? const Color(0xFF03AF74) : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Start location row
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF03AF74).withOpacity(0.14),
                              ),
                              child: const Icon(Icons.my_location, color: Color(0xFF03AF74), size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Start Location', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // End location – tap to open search
                      GestureDetector(
                        onTap: _openSearchMode,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: scheme.error, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('End Location', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _destAddress.isEmpty ? 'Where to?' : _destAddress,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _destAddress.isEmpty
                                            ? scheme.onSurfaceVariant.withOpacity(0.6)
                                            : scheme.onSurface,
                                        fontSize: 13,
                                        fontWeight: _destAddress.isEmpty ? FontWeight.w400 : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isSearchingDest)
                                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              else
                                Icon(Icons.search, color: scheme.primary, size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Available seats row
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF03AF74).withOpacity(0.14),
                              ),
                              child: const Icon(Icons.event_seat_rounded, color: Color(0xFF03AF74), size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Available Seats',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
                              ),
                            ),
                            // Decrement
                            GestureDetector(
                              onTap: _availableSeats > 1 ? () => setState(() => _availableSeats--) : null,
                              child: Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _availableSeats > 1
                                      ? const Color(0xFF03AF74).withOpacity(0.12)
                                      : scheme.onSurfaceVariant.withOpacity(0.08),
                                ),
                                child: Icon(Icons.remove,
                                  size: 16,
                                  color: _availableSeats > 1 ? const Color(0xFF03AF74) : scheme.onSurfaceVariant.withOpacity(0.4),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '$_availableSeats',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF03AF74)),
                              ),
                            ),
                            // Increment
                            GestureDetector(
                              onTap: _availableSeats < 6 ? () => setState(() => _availableSeats++) : null,
                              child: Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _availableSeats < 6
                                      ? const Color(0xFF03AF74).withOpacity(0.12)
                                      : scheme.onSurfaceVariant.withOpacity(0.08),
                                ),
                                child: Icon(Icons.add,
                                  size: 16,
                                  color: _availableSeats < 6 ? const Color(0xFF03AF74) : scheme.onSurfaceVariant.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Note field
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF03AF74).withOpacity(0.14),
                              ),
                              child: const Icon(Icons.notes_rounded, color: Color(0xFF03AF74), size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _noteController,
                                maxLines: 1,
                                style: TextStyle(fontSize: 13, color: scheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: 'Add a note for passengers...',
                                  hintStyle: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant.withOpacity(0.6)),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Route info
                      if (_isFetchingRoute)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text('Calculating route...', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        )
                      else if (_routeDistanceKm != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF03AF74).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF03AF74).withOpacity(0.25)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.straighten_rounded, size: 16, color: Color(0xFF03AF74)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_routeDistanceKm!.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF03AF74),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_routeDuration != null) ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF040F1B).withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF040F1B).withOpacity(0.1)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF040F1B)),
                                        const SizedBox(width: 6),
                                        Text(
                                          _routeDuration!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF040F1B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      // Start Ride button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (_isAvailable && _destLatLng != null) ? _onStartRide : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF03AF74),
                            disabledBackgroundColor: const Color(0xFF03AF74).withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Start Ride',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                      if (!_isAvailable)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Go online to start accepting rides',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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

  // ── search overlay ─────────────────────────────────────────────

  static const Color _navyDark = Color(0xFF040F1B);
  static const Color _primaryGreen = Color(0xFF169F7E);
  static const Color _accentGreen = Color(0xFF03AF74);
  static const Color _creamBg = Color(0xFFFFFFF0);
  static const Color _textPrimary = Color(0xFF040F1B);
  static const Color _textSecondary = Color(0xFF4A5565);

  Widget _buildSearchOverlay() {
    return Positioned.fill(
      child: Material(
        color: _creamBg,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: _navyDark,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 4))],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: _closeSearchMode,
                            splashRadius: 22,
                          ),
                          const Expanded(
                            child: Text('Set Destination', textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 26,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    Container(
                                      width: 14, height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle, color: _accentGreen,
                                        boxShadow: [BoxShadow(color: _accentGreen.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)],
                                      ),
                                    ),
                                    Expanded(
                                      child: SizedBox(
                                        width: 2,
                                        child: CustomPaint(painter: _DottedLinePainter(color: Colors.white.withOpacity(0.3))),
                                      ),
                                    ),
                                    Container(
                                      width: 14, height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFFF6B35), width: 2.5),
                                      ),
                                      child: const Center(child: Icon(Icons.circle, color: Color(0xFFFF6B35), size: 6)),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  children: [
                                    // Start location (read-only)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: _accentGreen.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('FROM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _accentGreen, letterSpacing: 1)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(_currentAddress, maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // End location (search field)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: _primaryGreen.withOpacity(0.5), width: 1.5),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF6B35).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFFF6B35), letterSpacing: 1)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller: _searchController,
                                              focusNode: _searchFocusNode,
                                              onChanged: _onSearchChanged,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                                              cursorColor: _primaryGreen,
                                              decoration: InputDecoration(
                                                hintText: 'Where are you going?',
                                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14, fontWeight: FontWeight.w400),
                                                filled: true, fillColor: Colors.transparent,
                                                border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                                                isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                              ),
                                            ),
                                          ),
                                          if (_isSearchingPlaces)
                                            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryGreen))
                                          else if (_searchController.text.isNotEmpty)
                                            GestureDetector(
                                              onTap: () { _searchController.clear(); _onSearchChanged(''); },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                                                child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.5), size: 16),
                                              ),
                                            )
                                          else
                                            Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.35), size: 20),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final hasQuery = _searchController.text.trim().length >= 2;

    if (!hasQuery) {
      if (_recentSearches.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _primaryGreen.withOpacity(0.08)),
                child: Icon(Icons.explore_rounded, size: 40, color: _primaryGreen.withOpacity(0.5)),
              ),
              const SizedBox(height: 20),
              const Text('Where are you heading?', style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Search for a destination', textAlign: TextAlign.center,
                style: TextStyle(color: _textSecondary, fontSize: 14, height: 1.5)),
            ],
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: _primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.history_rounded, size: 16, color: _primaryGreen),
                ),
                const SizedBox(width: 10),
                const Text('Recent Searches', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: 0.3)),
              ],
            ),
          ),
          ..._recentSearches.map((r) => _buildResultTile(
            icon: Icons.access_time_rounded,
            iconBg: _primaryGreen.withOpacity(0.08),
            iconColor: _primaryGreen,
            mainText: r['name'] ?? '',
            secondaryText: r['address'] ?? '',
            onTap: () => _selectRecentSearch(r),
          )),
        ],
      );
    }

    if (_isSearchingPlaces && _placePredictions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 40, height: 40,
              child: CircularProgressIndicator(strokeWidth: 3, color: _primaryGreen, backgroundColor: _primaryGreen.withOpacity(0.1))),
            const SizedBox(height: 16),
            const Text('Searching places...', style: TextStyle(color: _textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    if (_placePredictions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.shade50),
                child: Icon(Icons.location_off_rounded, size: 32, color: Colors.red.shade300),
              ),
              const SizedBox(height: 16),
              const Text('No results found', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: _placePredictions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFFF6B35).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.place_rounded, size: 16, color: Color(0xFFFF6B35)),
                ),
                const SizedBox(width: 10),
                Text('${_placePredictions.length} places found',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: 0.3)),
              ],
            ),
          );
        }
        final p = _placePredictions[index - 1];
        return _buildResultTile(
          icon: Icons.location_on_rounded,
          iconBg: const Color(0xFFFF6B35).withOpacity(0.08),
          iconColor: const Color(0xFFFF6B35),
          mainText: p['main_text'] as String? ?? '',
          secondaryText: p['secondary_text'] as String? ?? '',
          onTap: () => _selectPrediction(p),
        );
      },
    );
  }

  Widget _buildResultTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String mainText,
    required String secondaryText,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: _primaryGreen.withOpacity(0.08),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _navyDark.withOpacity(0.04)),
              boxShadow: [BoxShadow(color: _navyDark.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mainText, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
                      if (secondaryText.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(secondaryText, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: _textSecondary)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _primaryGreen.withOpacity(0.08)),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: _primaryGreen, size: 14),
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
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 3 && _currentLatLng != null) {
            _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 16));
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
          NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'Notifications'),
          NavigationDestination(icon: Icon(Icons.local_taxi_outlined), selectedIcon: Icon(Icons.local_taxi), label: 'Active Rides'),
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter({this.color = Colors.grey});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    const dashHeight = 3.0, dashSpace = 4.0;
    double y = 0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
