import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../core/routes/app_routes.dart';
import '../models/driver_profile.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/driver_service.dart';
import '../services/file_service.dart';
import '../services/ride_service.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_back_button.dart';
import 'available_rides_screen.dart';
import 'driver_home_mixin.dart';

class UserHomeMapScreen extends StatefulWidget {
  const UserHomeMapScreen({super.key});

  @override
  State<UserHomeMapScreen> createState() => _UserHomeMapScreenState();
}

class _UserHomeMapScreenState extends State<UserHomeMapScreen> with DriverHomeMixin {
  final ImagePicker _imagePicker = ImagePicker();

  // ── bottom nav ──
  int _selectedIndex = 3;

  // ── profile ──
  bool _isLoadingProfile = true;
  bool _isUploadingPhoto = false;
  bool _isChangingRole = false;
  String? _loadError;
  UserProfile? _userProfile;

  // ── DriverHomeMixin interface ──
  @override
  UserProfile? get currentUserProfile => _userProfile;
  @override
  LatLng? get currentPickupLatLng => _pickupLatLng;
  @override
  LatLng? get currentDropLatLng => _dropLatLng;
  @override
  String get currentPickupAddress => _pickupAddress;
  @override
  String get currentDropAddress => _dropAddress;
  @override
  double? get currentRouteDistanceKm => _routeDistanceKm;
  @override
  @override
  String? get currentRouteDuration => _routeDuration;
  @override
  List<LatLng> get currentPolylinePoints =>
      _polylines.isNotEmpty ? _polylines.first.points : [];

  @override
  void onActiveRideConflict() {
    // Switch to Active Rides tab and reload the ride data
    setState(() => _selectedIndex = 2);
    _loadActiveRide();
  }

  // ── map / ride ──
  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);

  // Sri Lanka bounding box — restrict camera & search to this area
  static const LatLng _slSouthWest = LatLng(5.916, 79.521);
  static const LatLng _slNorthEast = LatLng(9.836, 81.879);
  static final LatLngBounds _sriLankaBounds = LatLngBounds(
    southwest: _slSouthWest,
    northeast: _slNorthEast,
  );

  static const String _darkMapStyle = '[{"elementType":"geometry","stylers":[{"color":"#1d1f24"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#8a8f98"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#1d1f24"}]},{"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#3b3f47"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f7682"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#3a3f48"}]},{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#2a2e36"}]},{"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#525861"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#5f6670"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#474e57"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2d3139"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f2a36"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4d7a8d"}]}]';

  GoogleMapController? _mapController;
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  String _pickupAddress = 'Detecting current location...';
  String _dropAddress = '';
  bool _isLocating = true;
  bool _isSearchingDrop = false;
  String? _locationError;
  final TextEditingController _dropController = TextEditingController();

  // ── route ──
  Set<Polyline> _polylines = {};
  double? _routeDistanceKm;
  String? _routeDuration;
  bool _isFetchingRoute = false;

  // ── active ride ──
  bool _isLoadingActiveRide = false;
  bool _isEndingRide = false;
  bool _isCancellingRide = false;
  Map<String, dynamic>? _activeRideData;

  // ── search mode ──
  bool _isSearchMode = false;
  bool _isPickupSearchMode = false;
  bool _isSearchingPlaces = false;
  Timer? _searchDebounceTimer;
  List<Map<String, dynamic>> _placePredictions = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, String>> _recentSearches = [];

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
    disposeDriverState();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
        _pickupLatLng = latLng;
        _pickupAddress = 'Current Location';
      });
      // Animate camera — works whether map is already created or not
      _moveCameraToPickup(latLng);

      final address = await _resolveAddress(latLng);
      if (!mounted) return;
      setState(() => _pickupAddress = address);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _moveCameraToPickup(LatLng latLng) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
  }

  static const String _gMapsKey = 'AIzaSyAaIKIFaESxfhuchdlrRRQh7r6y9UhU9Uo';

  Future<String> _resolveAddress(LatLng latLng) async {
    // ── Method 1: Native platform geocoder (free, no API key needed) ──
    // Skip on web — the native geocoder is unreliable in browsers.
    if (!kIsWeb) {
      try {
        final placemarks = await placemarkFromCoordinates(
          latLng.latitude,
          latLng.longitude,
        );
        if (placemarks.isNotEmpty) {
          final address = _buildShortAddress(placemarks.first);
          if (address.isNotEmpty) {
            debugPrint('[Geocoding] Native resolved: $address');
            return address;
          }
        }
      } catch (e) {
        debugPrint('[Geocoding] Native geocoder failed: $e');
      }
    }

    // ── Method 2: OpenStreetMap Nominatim (free, CORS-friendly, works on web) ──
    try {
      final nominatimUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${latLng.latitude}&lon=${latLng.longitude}'
        '&format=json&zoom=16&addressdetails=1'
        '&countrycodes=lk',
      );
      // On web, browsers forbid setting User-Agent; omit custom headers.
      final headers = kIsWeb
          ? <String, String>{'Accept-Language': 'en'}
          : <String, String>{
              'User-Agent': 'RideMateApp/1.0',
              'Accept-Language': 'en',
            };
      final resp = await http.get(nominatimUrl, headers: headers);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final shortName = _extractNominatimShortName(addr);
          if (shortName.isNotEmpty) {
            debugPrint('[Geocoding] Nominatim resolved: $shortName');
            return shortName;
          }
        }
        // Fallback to display_name
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          // Take only the first 2-3 parts to keep it short
          final nameParts = displayName.split(',').map((s) => s.trim()).toList();
          final short = nameParts.take(2).join(', ');
          debugPrint('[Geocoding] Nominatim display_name: $short');
          return short;
        }
      }
    } catch (e) {
      debugPrint('[Geocoding] Nominatim failed: $e');
    }

    // ── Method 3: Google Geocoding REST API ──
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${latLng.latitude},${latLng.longitude}'
        '&region=lk'
        '&key=$_gMapsKey',
      );
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final status = data['status'] as String?;
        debugPrint('[Geocoding] Google API status: $status');
        if (status == 'OK') {
          final results = data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final shortName = _extractShortName(results);
            if (shortName != null && shortName.isNotEmpty) return shortName;
            return results[0]['formatted_address'] as String;
          }
        }
      }
    } catch (e) {
      debugPrint('[Geocoding] Google API failed: $e');
    }

    // ── Last resort: raw coordinates ──
    debugPrint('[Geocoding] All methods failed, using coordinates');
    return _coordString(latLng);
  }

  /// Extracts a short name from Nominatim address components.
  String _extractNominatimShortName(Map<String, dynamic> addr) {
    final suburb = addr['suburb'] as String?;
    final neighbourhood = addr['neighbourhood'] as String?;
    final city = addr['city'] as String?;
    final town = addr['town'] as String?;
    final village = addr['village'] as String?;
    final road = addr['road'] as String?;

    final area = suburb ?? neighbourhood ?? road ?? '';
    final place = city ?? town ?? village ?? '';

    if (area.isNotEmpty && place.isNotEmpty && area != place) {
      return '$area, $place';
    }
    if (place.isNotEmpty) return place;
    if (area.isNotEmpty) return area;
    return '';
  }

  /// Builds a short, human-readable address from a [Placemark].
  String _buildShortAddress(Placemark place) {
    final parts = <String>[];

    // Prefer subLocality (neighborhood / area)
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
      parts.add(place.thoroughfare!);
    } else if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }

    // Add locality (city)
    if (place.locality != null &&
        place.locality!.isNotEmpty &&
        !parts.contains(place.locality)) {
      parts.add(place.locality!);
    }

    // If still empty, try administrative area (province/district)
    if (parts.isEmpty &&
        place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }

    // If everything is empty, use name + country
    if (parts.isEmpty) {
      final name = place.name ?? '';
      final country = place.country ?? '';
      if (name.isNotEmpty) return name;
      if (country.isNotEmpty) return country;
    }

    return parts.join(', ');
  }

  /// Extracts a short, human-readable name from Google Geocoding API results.
  String? _extractShortName(List results) {
    final components = results[0]['address_components'] as List?;
    if (components == null) return null;

    String? street;
    String? sublocality;
    String? locality;
    String? adminArea;

    for (final comp in components) {
      final types = (comp['types'] as List?)?.cast<String>() ?? [];
      if (types.contains('route')) {
        street ??= comp['long_name'] as String?;
      }
      if (types.contains('sublocality_level_1') || types.contains('sublocality')) {
        sublocality ??= comp['long_name'] as String?;
      }
      if (types.contains('locality')) {
        locality ??= comp['long_name'] as String?;
      }
      if (types.contains('administrative_area_level_2') ||
          types.contains('administrative_area_level_1')) {
        adminArea ??= comp['long_name'] as String?;
      }
    }

    final parts = <String>[];
    if (sublocality != null) {
      parts.add(sublocality);
    } else if (street != null) {
      parts.add(street);
    }
    if (locality != null && locality != sublocality) {
      parts.add(locality);
    } else if (adminArea != null && !parts.contains(adminArea)) {
      parts.add(adminArea);
    }

    return parts.isNotEmpty ? parts.join(', ') : null;
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
    // Ignore taps while search overlay is visible or a selection is being resolved
    if (_isSearchMode || _isSearchingDrop) return;

    // If pickup is missing (location failed), let user set it by tapping the map
    if (_pickupLatLng == null) {
      final address = await _resolveAddress(latLng);
      if (!mounted) return;
      setState(() {
        _pickupLatLng = latLng;
        _pickupAddress = address;
        _locationError = null;
      });
      _moveCameraToPickup(latLng);
      return;
    }
    if (_dropLatLng != null) return;
    final address = await _resolveAddress(latLng);
    if (!mounted) return;
    setState(() {
      _dropLatLng = latLng;
      _dropAddress = address;
      _dropController.text = address;
    });
    _fetchRoute();
  }

  void _onConfirm() {
    if (_pickupLatLng == null || _dropLatLng == null || _routeDistanceKm == null) return;

    // Show a bottom sheet confirming the ride before calling the API
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PassengerConfirmSheet(
        pickupAddress: _pickupAddress,
        dropAddress: _dropAddress,
        distanceKm: _routeDistanceKm!,
        pickupLatLng: _pickupLatLng!,
        dropLatLng: _dropLatLng!,
        userProfile: _userProfile,
      ),
    );
  }

  Future<void> _fetchRoute() async {
    final origin = _pickupLatLng;
    final destination = _dropLatLng;
    if (origin == null || destination == null) return;

    setState(() { _isFetchingRoute = true; _polylines = {}; _routeDistanceKm = null; _routeDuration = null; });

    // Vehicle-type-aware routing for drivers
    final routeColor = driverRouteColor;

    // ── 1. OSRM with GeoJSON geometry (no decoding needed) ──
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving'
        '/${origin.longitude},${origin.latitude}'
        ';${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );
      final resp = await http.get(url, headers: {'User-Agent': 'RideMateApp/1.0'});
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['code'] == 'Ok') {
          final route = data['routes'][0];
          final distanceM = (route['distance'] as num).toDouble();
          final durationSec = (route['duration'] as num).toDouble();

          // Parse GeoJSON coordinates → List<LatLng>
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List;
          final points = coordinates.map<LatLng>((coord) {
            return LatLng(
              (coord[1] as num).toDouble(), // latitude
              (coord[0] as num).toDouble(), // longitude (GeoJSON = [lng, lat])
            );
          }).toList();

          debugPrint('[Route] OSRM GeoJSON decoded ${points.length} points');
          if (points.isNotEmpty) {
            debugPrint('[Route] First: ${points.first}, Last: ${points.last}');
          }

          final bounds = _boundsFromLatLngs([origin, destination, ...points]);
          _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
          final mins = (durationSec / 60).round();
          final durationText = mins >= 60
              ? '${mins ~/ 60}h ${mins % 60}m'
              : '${mins}m';
          if (mounted) setState(() {
            _routeDistanceKm = distanceM / 1000;
            _routeDuration = durationText;
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: routeColor,
                width: 5,
              ),
            };
            _isFetchingRoute = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[Route] OSRM error: $e');
    }

    // ── 2. Google Directions fallback (mobile/non-CORS environments) ──
    final googleMode = driverGoogleMode;
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$googleMode'
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
          final encodedPolyline = route['overview_polyline']['points'] as String;
          final points = _decodePolyline(encodedPolyline);

          debugPrint('[Route] Google decoded ${points.length} points');
          if (points.isNotEmpty) {
            debugPrint('[Route] First: ${points.first}, Last: ${points.last}');
          }

          final bounds = _boundsFromLatLngs([origin, destination, ...points]);
          _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
          if (mounted) setState(() {
            _routeDistanceKm = distanceM / 1000;
            _routeDuration = durationText;
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: routeColor,
                width: 5,
              ),
            };
            _isFetchingRoute = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[Route] Google Directions error: $e');
    }


    if (mounted) setState(() => _isFetchingRoute = false);
  }

  /// Decode Google encoded polyline using flutter_polyline_points package.
  List<LatLng> _decodePolyline(String encoded) {
    final decoded = PolylinePoints.decodePolyline(encoded);
    debugPrint('[Polyline] Decoded ${decoded.length} points from encoded string');
    if (decoded.length >= 3) {
      debugPrint('[Polyline] First 3 points: ${decoded.take(3).map((p) => '(${p.latitude}, ${p.longitude})').toList()}');
    }
    return decoded
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
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

  // ── search helpers ──────────────────────────────────────────────

  void _openSearchMode({bool forPickup = false}) {
    setState(() {
      _isSearchMode = true;
      _isPickupSearchMode = forPickup;
      _searchController.clear();
      _placePredictions = [];
      if (!forPickup) {
        _dropLatLng = null;
        _dropAddress = '';
        _dropController.clear();
        _polylines = {};
        _routeDistanceKm = null;
        _routeDuration = null;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearchMode() {
    _searchDebounceTimer?.cancel();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearchMode = false;
      _isPickupSearchMode = false;
      _placePredictions = [];
      _isSearchingPlaces = false;
      _searchController.clear();
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _placePredictions = [];
        _isSearchingPlaces = false;
      });
      return;
    }
    setState(() => _isSearchingPlaces = true);
    _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchPlacePredictions(trimmed);
    });
  }

  Future<void> _fetchPlacePredictions(String input) async {
    // ── Try Google Places Autocomplete first (works on Android/iOS) ──
    try {
      final loc = _pickupLatLng ?? _defaultCenter;
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
        final status = data['status'] as String? ?? 'UNKNOWN';
        debugPrint('[Places] Google Autocomplete status: $status');
        if (status == 'OK') {
          setState(() {
            _placePredictions = (data['predictions'] as List)
                .map<Map<String, dynamic>>((p) => {
                      'place_id': p['place_id'] ?? '',
                      'description': p['description'] ?? '',
                      'main_text': (p['structured_formatting']?['main_text'] ??
                          p['description'] ??
                          '') as String,
                      'secondary_text':
                          (p['structured_formatting']?['secondary_text'] ?? '') as String,
                      'source': 'google',
                    })
                .toList();
            _isSearchingPlaces = false;
          });
          return; // Google succeeded — skip fallback
        } else {
          debugPrint('[Places] Google error_message: ${data['error_message'] ?? 'none'}');
        }
      }
    } catch (e) {
      debugPrint('[Places] Google Autocomplete error: $e');
    }

    // ── Fallback: Nominatim search (free, reliable, no API key needed) ──
    try {
      debugPrint('[Places] Trying Nominatim for "$input"');
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(input)}'
        '&format=json'
        '&addressdetails=1'
        '&limit=8'
        '&countrycodes=lk'
        '&accept-language=en',
      );
      final headers = <String, String>{
        'User-Agent': 'RideMateApp/1.0',
        'Accept-Language': 'en',
      };
      final resp = await http.get(url, headers: headers);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final results = json.decode(resp.body) as List;
        debugPrint('[Places] Nominatim returned ${results.length} results');

        if (results.isNotEmpty) {
          setState(() {
            _placePredictions = results.take(8).map<Map<String, dynamic>>((r) {
              final addr = r['address'] as Map<String, dynamic>? ?? {};
              final displayName = r['display_name'] as String? ?? '';
              final lat = double.tryParse(r['lat']?.toString() ?? '') ?? 0.0;
              final lon = double.tryParse(r['lon']?.toString() ?? '') ?? 0.0;

              // Build main text (short name)
              final mainText = addr['road'] ??
                  addr['suburb'] ??
                  addr['neighbourhood'] ??
                  addr['city'] ??
                  addr['town'] ??
                  addr['village'] ??
                  displayName.split(',').first.trim();

              // Build secondary text
              final secondaryParts = <String>[];
              for (final key in ['suburb', 'city', 'town', 'state_district', 'state']) {
                final val = addr[key] as String?;
                if (val != null && val.isNotEmpty && val != mainText) {
                  secondaryParts.add(val);
                }
              }

              return {
                'place_id': '',
                'description': displayName,
                'main_text': mainText as String,
                'secondary_text': secondaryParts.take(2).join(', '),
                'source': 'nominatim',
                'lat': lat,
                'lon': lon,
              };
            }).toList();
            _isSearchingPlaces = false;
          });
          return; // Nominatim succeeded — skip Photon
        }
      }
    } catch (e) {
      debugPrint('[Places] Nominatim search error: $e');
    }

    // ── Fallback 2: Photon API ──
    try {
      debugPrint('[Places] Trying Photon for "$input"');
      final loc = _pickupLatLng ?? _defaultCenter;
      final url = Uri.parse(
        'https://photon.komoot.io/api/'
        '?q=${Uri.encodeComponent(input)}'
        '&limit=10'
        '&lang=en'
        '&lat=${loc.latitude}'
        '&lon=${loc.longitude}'
        '&bbox=${_slSouthWest.longitude},${_slSouthWest.latitude},'
        '${_slNorthEast.longitude},${_slNorthEast.latitude}',
      );
      final resp = await http.get(url);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final features = (data['features'] as List?) ?? [];
        debugPrint('[Places] Photon returned ${features.length} results');

        // Only show Sri Lanka results
        final sriLankaResults = features.where((f) {
          final country =
              (f['properties'] as Map<String, dynamic>?)?['country'] as String?;
          return country != null &&
              country.toLowerCase().contains('sri lanka');
        }).toList();

        setState(() {
          _placePredictions =
              sriLankaResults.take(7).map<Map<String, dynamic>>((f) {
            final props = f['properties'] as Map<String, dynamic>? ?? {};
            final coords =
                (f['geometry']?['coordinates'] as List?) ?? [0.0, 0.0];
            final mainText = (props['name'] ?? '') as String;

            // Build secondary text: city, state, country
            final secondaryParts = <String>[];
            for (final key in ['city', 'county', 'state', 'country']) {
              final val = props[key] as String?;
              if (val != null && val.isNotEmpty && val != mainText) {
                secondaryParts.add(val);
              }
            }

            return {
              'place_id': '',
              'description': '$mainText, ${secondaryParts.join(', ')}',
              'main_text': mainText,
              'secondary_text': secondaryParts.join(', '),
              'source': 'photon',
              'lat': (coords[1] as num).toDouble(), // GeoJSON: [lon, lat]
              'lon': (coords[0] as num).toDouble(),
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('[Places] Photon search error: $e');
      if (mounted) setState(() => _placePredictions = []);
    } finally {
      if (mounted) setState(() => _isSearchingPlaces = false);
    }
  }

  Future<void> _selectPrediction(Map<String, dynamic> prediction) async {
    final source = prediction['source'] as String? ?? 'google';
    final mainText = prediction['main_text'] as String;
    final description = prediction['description'] as String;

    final isPickup = _isPickupSearchMode;

    // Do NOT close the search overlay yet — keep it as a touch barrier
    // until coordinates are fully resolved, preventing stray map taps.
    setState(() => _isSearchingDrop = !isPickup);

    try {
      LatLng latLng;

      if (source == 'photon' || source == 'nominatim') {
        // Photon / Nominatim results already include coordinates
        latLng = LatLng(
          (prediction['lat'] as num).toDouble(),
          (prediction['lon'] as num).toDouble(),
        );
      } else {
        // Google Places: resolve place_id → LatLng via Details API
        final placeId = prediction['place_id'] as String;
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&key=$_gMapsKey'
          '&fields=geometry',
        );
        final resp = await http.get(url);
        if (!mounted) return;
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          if (data['status'] == 'OK') {
            final loc = data['result']['geometry']['location'];
            latLng = LatLng(
              (loc['lat'] as num).toDouble(),
              (loc['lng'] as num).toDouble(),
            );
          } else {
            throw Exception('Could not resolve location.');
          }
        } else {
          throw Exception('Could not resolve location.');
        }
      }

      if (!mounted) return;

      // Close the search overlay NOW — coordinates are resolved,
      // so _dropLatLng will be set in the same frame.
      _closeSearchMode();

      if (isPickup) {
        setState(() {
          _pickupLatLng = latLng;
          _pickupAddress = mainText;
          _locationError = null;
        });
        _moveCameraToPickup(latLng);
        if (_dropLatLng != null) _fetchRoute();
      } else {
        setState(() {
          _dropLatLng = latLng;
          _dropAddress = mainText;
          _dropController.text = mainText;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
        _fetchRoute();
      }

      // Save to recents (include coordinates for instant re-selection)
      _recentSearches.removeWhere((r) => r['name'] == mainText);
      _recentSearches.insert(0, {
        'name': mainText,
        'address': description,
        'place_id': prediction['place_id']?.toString() ?? '',
        'lat': latLng.latitude.toString(),
        'lon': latLng.longitude.toString(),
        'source': source,
      });
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.sublist(0, 5);
      }
    } catch (e) {
      if (!mounted) return;
      // Close the search overlay on error (it was kept open during resolution)
      if (_isSearchMode) _closeSearchMode();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red.shade700,
      ));
    } finally {
      if (mounted) setState(() => _isSearchingDrop = false);
    }
  }

  void _selectRecentSearch(Map<String, String> recent) {
    final lat = double.tryParse(recent['lat'] ?? '');
    final lon = double.tryParse(recent['lon'] ?? '');

    if (lat != null && lon != null) {
      // We have saved coordinates — use them directly
      _selectPrediction({
        'place_id': recent['place_id'] ?? '',
        'main_text': recent['name'] ?? '',
        'description': recent['address'] ?? '',
        'source': recent['source'] ?? 'nominatim',
        'lat': lat,
        'lon': lon,
      });
    } else {
      // Fallback: use the name as a text search
      _closeSearchMode();
      _searchDrop(recent['name'] ?? '');
    }
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

      // If user is a driver, fetch the driver profile for vehicle type info
      if (profile.role.toUpperCase() == 'DRIVER') {
        await fetchDriverProfile(userId);
        // Load active ride — driverProfile is now set
        if (driverProfile != null) {
          _loadActiveRide();
        } else {
          debugPrint('[UserHome] driverProfile still null after fetch — skipping active ride load');
        }
      }

      // Check driver profile if user is willing to drive
      if (profile.isProfileCompleted && profile.isWillingToDrive) {
        await checkDriverProfileStatus(userId);
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

  /// Load the driver's active ride from the backend.
  Future<void> _loadActiveRide() async {
    final dp = driverProfile;
    if (dp == null && activeRideDetailId == null) {
      debugPrint('[ActiveRide] No driver profile or rideId — skipping load');
      return;
    }

    setState(() => _isLoadingActiveRide = true);
    try {
      // Primary method: Use the status-filtered endpoint
      if (dp != null) {
        try {
          final rides = await RideService.getDriverRidesByStatus(dp.id, 'ACTIVE');
          debugPrint('[ActiveRide] getDriverRidesByStatus returned ${rides.length} rides');
          if (!mounted) return;
          if (rides.isNotEmpty) {
            final data = rides.first;
            debugPrint('[ActiveRide] ride data: $data');
            setState(() {
              _activeRideData = data;
              activeRideDetailId = (data['id'] as num?)?.toInt();
              _isLoadingActiveRide = false;
            });
            return;
          }
        } catch (e) {
          debugPrint('[ActiveRide] getDriverRidesByStatus error: $e');
          // Endpoint might not exist — continue to fallback
        }
      }

      // Fallback: Try the dedicated active-ride endpoint
      if (dp != null) {
        try {
          final data = await RideService.getDriverActiveRide(dp.id);
          debugPrint('[ActiveRide] getDriverActiveRide returned: $data');
          if (!mounted) return;
          if (data != null) {
            setState(() {
              _activeRideData = data;
              activeRideDetailId = (data['id'] as num?)?.toInt();
              _isLoadingActiveRide = false;
            });
            return;
          }
        } catch (e) {
          debugPrint('[ActiveRide] getDriverActiveRide error: $e');
          // Endpoint might not exist — continue
        }
      }

      // Fallback: If we already know the rideId, load cost-split for details
      if (activeRideDetailId != null) {
        try {
          final costSplit = await RideService.getCostSplit(activeRideDetailId!);
          if (!mounted) return;
          setState(() {
            _activeRideData = {
              'id': costSplit.rideDetailId,
              'totalRideCost': costSplit.totalRideCost,
              'totalRideDistance': costSplit.totalRideDistance,
              'perKmRate': costSplit.perKmRate,
              'startCity': costSplit.driverStartCity ?? _pickupAddress,
              'endCity': _dropAddress,
              'status': 'ACTIVE',
              'availableSeats': driverAvailableSeats,
              'tripRoute': '$_pickupAddress -> $_dropAddress',
            };
            _isLoadingActiveRide = false;
          });
          return;
        } catch (_) {
          // Cost split not available yet, continue
        }
      }

      // If we have a local ride id but couldn't load details, show minimal card
      if (activeRideDetailId != null) {
        if (!mounted) return;
        setState(() {
          _activeRideData = {
            'id': activeRideDetailId,
            'totalRideCost': ridePrice?.totalRidePrice ?? 0.0,
            'totalRideDistance': _routeDistanceKm ?? 0.0,
            'perKmRate': ridePrice?.perKmRate ?? 0.0,
            'startCity': _pickupAddress,
            'endCity': _dropAddress,
            'status': 'ACTIVE',
            'availableSeats': driverAvailableSeats,
            'tripRoute': '$_pickupAddress -> $_dropAddress',
          };
          _isLoadingActiveRide = false;
        });
        return;
      }

      // No active ride found
      if (mounted) {
        setState(() {
          _activeRideData = null;
          activeRideDetailId = null;
          _isLoadingActiveRide = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingActiveRide = false);
    }
  }

  /// End the currently active ride.
  Future<void> _endActiveRide() async {
    final rideId = activeRideDetailId;
    if (rideId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End This Ride?'),
        content: const Text(
          'This will mark the ride as completed. Passengers will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Ride', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isEndingRide = true);
    try {
      await RideService.endRide(rideId);
      if (!mounted) return;
      setState(() {
        activeRideDetailId = null;
        _activeRideData = null;
        _isEndingRide = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride ended successfully! 🎉'),
          backgroundColor: Color(0xFF03AF74),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isEndingRide = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  /// Cancel the currently active ride.
  Future<void> _cancelActiveRide() async {
    final rideId = activeRideDetailId;
    if (rideId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel This Ride?'),
        content: const Text(
          'This will cancel your active ride. You will be able to offer a new ride after cancellation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Keep Ride'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel Ride', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancellingRide = true);
    try {
      await RideService.cancelRide(rideId);
      if (!mounted) return;
      setState(() {
        activeRideDetailId = null;
        _activeRideData = null;
        _isCancellingRide = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride cancelled successfully! You can now offer a new ride.'),
          backgroundColor: Color(0xFF03AF74),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancellingRide = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  /// Switch role between DRIVER and PASSENGER via the Offer/Request toggle.
  Future<void> _onSwitchRole({required bool toDriver}) async {
    final profile = _userProfile;
    if (profile == null || _isChangingRole) return;

    // Already in the target role — nothing to do
    final currentIsDriver = profile.role.toUpperCase() == 'DRIVER';
    if (toDriver == currentIsDriver) return;

    final userId = await TokenService.getUserId();
    if (userId == null || !mounted) return;

    final newRole = toDriver ? 'DRIVER' : 'PASSENGER';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(toDriver ? 'Switch to Driver?' : 'Switch to Passenger?'),
        content: Text(
          toDriver
              ? 'You will switch to Driver mode. You may need to complete your driver profile if not done.'
              : 'Switch your role back to Passenger mode?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isChangingRole = true);
    try {
      await UserService.updateRole(userId, newRole);
      await _loadUserProfile();
      if (!mounted) return;

      if (newRole == 'DRIVER') {
        // Check if driver is already registered by calling the driver profile API
        try {
          final driverProfile =
              await DriverService.getDriverProfileByUserId(userId);
          if (!driverProfile.isDriverProfileCompleted) {
            // Driver profile exists but is not complete — go to registration
            if (mounted) {
              Navigator.pushNamed(context, AppRoutes.vehicleRegistration);
            }
          }
        } catch (_) {
          // Driver profile not found — navigate to vehicle registration
          if (mounted) {
            Navigator.pushNamed(context, AppRoutes.vehicleRegistration);
          }
        }
      } else {
        // Reset driver-specific state
        resetDriverState();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Switched to Passenger mode.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isChangingRole = false);
    }
  }

Future<void> _onChangeProfilePhoto() async {
  try {
    // STEP 1: Pick image
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file == null) {
      debugPrint('[Photo] No file selected');
      return;
    }

    if (!mounted) return;

    setState(() => _isUploadingPhoto = true);

    // STEP 2: Read file
    final bytes = await file.readAsBytes();
    final fileName =
        file.name.isNotEmpty ? file.name : file.path.split('/').last;

    debugPrint('[Photo] Uploading file: $fileName (${bytes.length} bytes)');

    // STEP 3: Upload file
    final documentId = await FileService.uploadFile(
      bytes: bytes,
      fileName: fileName,
    );

    debugPrint('[Photo] File uploaded, documentId=$documentId');

    // ✅ Validate documentId
    if (documentId == null || documentId.toString().isEmpty) {
      throw Exception('Upload failed: documentId is null or empty');
    }

    if (!mounted) return;

    // STEP 4: Get userId
    String? userId =
        _userProfile?.userId?.toString() ?? await TokenService.getUserId();

    debugPrint('[Photo] userId=$userId');

    if (userId == null || userId.isEmpty) {
      throw Exception('User not logged in');
    }

    // STEP 5: Call updateProfilePhoto
    try {
      debugPrint('[Photo] Calling updateProfilePhoto...');
      await UserService.updateProfilePhoto(userId, documentId);
      debugPrint('[Photo] updateProfilePhoto SUCCESS');
    } catch (updateError) {
      debugPrint('[Photo] updateProfilePhoto ERROR: $updateError');
      rethrow;
    }

    // STEP 6: Reload profile
    debugPrint('[Photo] Reloading user profile...');
    final updatedProfile =
        await UserService.getUserProfileByUserId(userId);

    if (!mounted) return;

    setState(() => _userProfile = updatedProfile);

    // SUCCESS UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile photo updated successfully.'),
        backgroundColor: Colors.green.shade700,
      ),
    );
  } catch (e) {
    debugPrint('[Photo] ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Photo update failed: ${e.toString().replaceFirst('Exception: ', '')}',
        ),
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
                    backgroundImage: (profile.profileImageUrl ?? '').isNotEmpty
                        ? NetworkImage(profile.profileImageUrl!)
                        : (profile.userVerificationImageUrl ?? '').isNotEmpty
                            ? NetworkImage(profile.userVerificationImageUrl!)
                            : null,
                    child: (profile.profileImageUrl ?? '').isNotEmpty ||
                            (profile.userVerificationImageUrl ?? '').isNotEmpty
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
                        if (isDriver) ...[
                          const SizedBox(height: 4),
                          buildDriverBadge(),
                        ],
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
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.profileCompletion,
                  arguments: _userProfile,
                ),
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
    // Loading state
    if (_isLoadingActiveRide && _activeRideData == null && activeRideDetailId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // If the driver has an active ride (from local state or fetched data)
    if (isDriver && (activeRideDetailId != null || _activeRideData != null)) {
      final ride = _activeRideData;
      final rideId = activeRideDetailId ?? (ride?['id'] as num?)?.toInt();
      final startCity = ride?['startCity'] as String? ?? _pickupAddress;
      final endCity = ride?['endCity'] as String? ?? _dropAddress;
      final totalDist = (ride?['totalRideDistance'] as num?)?.toDouble() ?? _routeDistanceKm ?? 0.0;
      final totalCost = (ride?['totalRideCost'] as num?)?.toDouble() ?? ridePrice?.totalRidePrice ?? 0.0;
      final perKm = (ride?['perKmRate'] as num?)?.toDouble() ?? ridePrice?.perKmRate ?? 0.0;
      final seats = (ride?['availableSeats'] as num?)?.toInt() ?? driverAvailableSeats;
      final status = ride?['status'] as String? ?? 'ACTIVE';
      final tripRoute = ride?['tripRoute'] as String? ?? '';
      final startTime = ride?['startTime'] as String? ?? '';

      return RefreshIndicator(
        onRefresh: _loadActiveRide,
        color: const Color(0xFF03AF74),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // ── Ride status header ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF040F1B), Color(0xFF0A1F35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF03AF74).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_car_filled,
                            color: Color(0xFF03AF74), size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ride #$rideId',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF03AF74),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Cost display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('TOTAL RIDE COST',
                            style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                            children: [
                              const TextSpan(text: 'LKR ', style: TextStyle(color: Color(0xFF03AF74))),
                              TextSpan(text: totalCost.toStringAsFixed(2), style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Route details card ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Route Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF040F1B))),
                  const SizedBox(height: 14),
                  // Pickup
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.radio_button_checked, color: Color(0xFF03AF74), size: 18),
                          Container(width: 2, height: 30, color: const Color(0xFF03AF74).withOpacity(0.3)),
                          const Icon(Icons.location_on, color: Colors.red, size: 18),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pickup', style: TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w600)),
                            Text(startCity, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF040F1B))),
                            const SizedBox(height: 18),
                            const Text('Destination', style: TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w600)),
                            Text(endCity, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF040F1B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (tripRoute.isNotEmpty) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.route, size: 16, color: Colors.black38),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(tripRoute, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ),
                      ],
                    ),
                  ],
                  if (startTime.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.black38),
                        const SizedBox(width: 8),
                        Text(
                          'Started: ${_formatStartTime(startTime)}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Stats row ──
            Row(
              children: [
                _buildStatCard(Icons.straighten, '${totalDist.toStringAsFixed(1)} km', 'Distance'),
                const SizedBox(width: 10),
                _buildStatCard(Icons.speed, 'LKR ${perKm.toStringAsFixed(0)}/km', 'Rate'),
                const SizedBox(width: 10),
                _buildStatCard(Icons.event_seat, '$seats', 'Seats'),
              ],
            ),
            const SizedBox(height: 16),
            // ── Action buttons ──
            // End Ride button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_isEndingRide || _isCancellingRide) ? null : _endActiveRide,
                icon: _isEndingRide
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.stop_circle_outlined),
                label: Text(
                  _isEndingRide ? 'Ending Ride...' : 'End Ride',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.red.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.activeRide,
                    arguments: {
                      'rideDetailId': rideId!,
                      'pickupAddress': startCity,
                      'dropAddress': endCity,
                      'totalDistance': totalDist,
                      'totalCost': totalCost,
                    },
                  );
                },
                icon: const Icon(Icons.analytics_outlined),
                label: const Text(
                  'View Ride Details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF040F1B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.costSplit,
                    arguments: {
                      'rideDetailId': rideId!,
                      'isDriver': true,
                    },
                  );
                },
                icon: const Icon(Icons.pie_chart_outline),
                label: const Text(
                  'View Cost Split',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF03AF74),
                  side: const BorderSide(color: Color(0xFF03AF74)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    // No active rides
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_taxi_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No active rides right now',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              isDriver
                  ? 'Go to Home tab and offer a ride to get started!'
                  : 'Browse available rides on the Home tab.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black38),
            ),
            if (isDriver) ...[
              const SizedBox(height: 20),
              _isLoadingActiveRide
                  ? const CircularProgressIndicator(color: Color(0xFF03AF74))
                  : TextButton.icon(
                      onPressed: _loadActiveRide,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF03AF74)),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatStartTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hour:$min $ampm';
    } catch (_) {
      return isoTime;
    }
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF03AF74)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF040F1B))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.w600)),
          ],
        ),
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
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted && _pickupLatLng != null) {
                    c.animateCamera(CameraUpdate.newLatLngZoom(_pickupLatLng!, 16));
                  }
                });
              }
            },
            style: _darkMapStyle,
            onTap: _onMapTap,
            initialCameraPosition: CameraPosition(
              target: _pickupLatLng ?? _defaultCenter,
              zoom: _pickupLatLng == null ? 11 : 16,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
            polylines: _polylines,
            // Restrict map to Sri Lanka
            cameraTargetBounds: CameraTargetBounds(_sriLankaBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(7, 20),
          ),
          // ── Offer Ride / Request Ride toggle ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Row(
                children: [
                  Expanded(child: _buildRideModeSwitcher()),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      // Open account / menu
                      setState(() => _selectedIndex = 0);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF040F1B),
                      ),
                      child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildRidePanel(),
          if (_isLocating)
            _buildBanner('Getting your current location...', Colors.black87),
          if (!_isLocating && _locationError != null)
            _buildErrorBanner(_locationError!),
          if (showDriverProfileCard) buildCompleteDriverProfileCard(),
          if (_isSearchMode) _buildSearchOverlay(),
        ],
      ),
    );
  }

  Widget _buildRideModeSwitcher() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF040F1B),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isChangingRole
                      ? null
                      : () => _onSwitchRole(toDriver: true),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDriver ? const Color(0xFF03AF74) : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Offer Ride',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDriver ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _isChangingRole
                      ? null
                      : () => _onSwitchRole(toDriver: false),
                  child: Container(
                    decoration: BoxDecoration(
                      color: !isDriver ? const Color(0xFF03AF74) : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Request Ride',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: !isDriver ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isChangingRole)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
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
        padding: const EdgeInsets.fromLTRB(14, 68, 14, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
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
                      // GPS refresh button + driver availability toggle
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
                          if (isDriver) ...[
                            const Spacer(),
                            buildAvailabilityToggle(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Pickup row – tappable to search when location failed
                      GestureDetector(
                        onTap: (_locationError != null || _pickupLatLng == null && !_isLocating)
                            ? () => _openSearchMode(forPickup: true)
                            : null,
                        child: _buildLocationRow(
                          icon: Icons.my_location,
                          iconColor: const Color(0xFF03AF74),
                          label: 'Pickup',
                          value: _pickupAddress,
                          scheme: scheme,
                          showSearchHint: _locationError != null || (_pickupLatLng == null && !_isLocating),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Drop location – tap to open search overlay
                      GestureDetector(
                        onTap: _openSearchMode,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                          decoration: BoxDecoration(
                            color: fill,
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
                                    Text(
                                      'Drop location',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _dropAddress.isEmpty ? 'Where to?' : _dropAddress,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _dropAddress.isEmpty
                                            ? scheme.onSurfaceVariant.withOpacity(0.6)
                                            : scheme.onSurface,
                                        fontSize: 13,
                                        fontWeight: _dropAddress.isEmpty
                                            ? FontWeight.w400
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isSearchingDrop)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Icon(Icons.search, color: scheme.primary, size: 22),
                            ],
                          ),
                        ),
                      ),
                      // ── Driver-only: available seats ──
                      if (isDriver) ...[
                        const SizedBox(height: 8),
                        buildSeatsSelector(scheme, border),
                        const SizedBox(height: 8),
                        buildNoteField(scheme, border),
                      ],
                      const SizedBox(height: 12),
                      // Route info (distance + duration)
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
                      // Action button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isOfferingRide
                              ? null
                              : isDriver
                                  ? ((isDriverAvailable && _pickupLatLng != null && _dropLatLng != null) ? onOfferRide : null)
                                  : ((_pickupLatLng != null && _dropLatLng != null) ? _onConfirm : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF03AF74),
                            disabledBackgroundColor: const Color(0xFF03AF74).withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isOfferingRide
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isDriver ? 'Offer Ride' : 'Confirm Ride',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                        ),
                      ),
                      if (isDriver && !isDriverAvailable)
                        buildOfflineHint(scheme),
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

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required ColorScheme scheme,
    bool showSearchHint = false,
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
                Text(
                  showSearchHint ? 'Tap to search pickup location' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: showSearchHint ? FontWeight.w400 : FontWeight.w600,
                    color: showSearchHint ? scheme.onSurfaceVariant.withOpacity(0.6) : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (showSearchHint)
            Icon(Icons.search, color: scheme.primary, size: 20),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(message, style: const TextStyle(color: Colors.white))),
                TextButton(
                  onPressed: _loadCurrentLocation,
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _openSearchMode(forPickup: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Select pickup manually', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── search overlay ─────────────────────────────────────────────

  // App theme constants for the search overlay
  static const Color _navyDark = Color(0xFF040F1B);
  static const Color _primaryGreen = Color(0xFF169F7E);
  static const Color _accentGreen = Color(0xFF03AF74);
  static const Color _creamBg = Color(0xFFFFFFF0);
  static const Color _textPrimary = Color(0xFF040F1B);
  static const Color _textSecondary = Color(0xFF4A5565);
  static const Color _inputFill = Color(0xFFF5F5F5);

  Widget _buildSearchOverlay() {
    return Positioned.fill(
      child: Material(
        color: _creamBg,
        child: Column(
          children: [
            // ── Dark header with PICKUP + DROP ──
            Container(
              decoration: const BoxDecoration(
                color: _navyDark,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header row ──
                      Row(
                        children: [
                          CustomBackButton(
                            onPressed: _closeSearchMode,
                          ),
                          Expanded(
                            child: Text(
                              _isPickupSearchMode ? 'Set Pickup Location' : 'Set Destination',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // ── PICKUP + DROP rows with connector ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left: icons + dotted line
                              SizedBox(
                                width: 26,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _accentGreen,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _accentGreen.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: SizedBox(
                                        width: 2,
                                        child: CustomPaint(
                                          painter: _DottedLinePainter(
                                            color: Colors.white.withOpacity(0.3),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFFF6B35),
                                          width: 2.5,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.circle,
                                          color: Color(0xFFFF6B35),
                                          size: 6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Right: PICKUP + DROP fields
                              Expanded(
                                child: Column(
                                  children: [
                                    // ── Pickup row ──
                                    _isPickupSearchMode
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: _accentGreen.withOpacity(0.5),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: _accentGreen.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'FROM',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: _accentGreen,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: TextField(
                                                  controller: _searchController,
                                                  focusNode: _searchFocusNode,
                                                  onChanged: _onSearchChanged,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                  cursorColor: _accentGreen,
                                                  decoration: InputDecoration(
                                                    hintText: 'Search pickup location...',
                                                    hintStyle: TextStyle(
                                                      color: Colors.white.withOpacity(0.35),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.transparent,
                                                    border: InputBorder.none,
                                                    enabledBorder: InputBorder.none,
                                                    focusedBorder: InputBorder.none,
                                                    isDense: true,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(vertical: 10),
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: _loadCurrentLocation,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white.withOpacity(0.08),
                                                  ),
                                                  child: Icon(
                                                    Icons.my_location_rounded,
                                                    color: Colors.white.withOpacity(0.5),
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 13),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.1),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: _accentGreen.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'FROM',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: _accentGreen,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _pickupAddress,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: _loadCurrentLocation,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white.withOpacity(0.08),
                                                  ),
                                                  child: Icon(
                                                    Icons.my_location_rounded,
                                                    color: Colors.white.withOpacity(0.5),
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    const SizedBox(height: 10),
                                    // ── Drop row ──
                                    _isPickupSearchMode
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 13),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.1),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF6B35)
                                                      .withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'TO',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFFFF6B35),
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _dropAddress.isEmpty ? 'Set after pickup' : _dropAddress,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.white.withOpacity(_dropAddress.isEmpty ? 0.35 : 1.0),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: _primaryGreen.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF6B35)
                                                  .withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'TO',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFFF6B35),
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller: _searchController,
                                              focusNode: _searchFocusNode,
                                              onChanged: _onSearchChanged,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                              cursorColor: _primaryGreen,
                                              decoration: InputDecoration(
                                                hintText: 'Where are you going?',
                                                hintStyle: TextStyle(
                                                  color: Colors.white.withOpacity(0.35),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                border: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10),
                                              ),
                                            ),
                                          ),
                                          if (_isSearchingPlaces)
                                            const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: _primaryGreen,
                                              ),
                                            )
                                          else if (_searchController.text.isNotEmpty)
                                            GestureDetector(
                                              onTap: () {
                                                _searchController.clear();
                                                _onSearchChanged('');
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white.withOpacity(0.1),
                                                ),
                                                child: Icon(
                                                  Icons.close_rounded,
                                                  color: Colors.white.withOpacity(0.5),
                                                  size: 16,
                                                ),
                                              ),
                                            )
                                          else
                                            Icon(
                                              Icons.search_rounded,
                                              color: Colors.white.withOpacity(0.35),
                                              size: 20,
                                            ),
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
            // ── Results list ──
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final hasQuery = _searchController.text.trim().length >= 2;

    // Show recent searches when no query
    if (!hasQuery) {
      if (_recentSearches.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryGreen.withOpacity(0.08),
                ),
                child: Icon(
                  Icons.explore_rounded,
                  size: 40,
                  color: _primaryGreen.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Where are you heading?',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Search for a place or tap the map\nto set your destination',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              // Quick suggestion chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildSuggestionChip('🏠  Home', Icons.home_rounded),
                  _buildSuggestionChip('🏢  Work', Icons.work_rounded),
                  _buildSuggestionChip('🍽️  Restaurant', Icons.restaurant_rounded),
                  _buildSuggestionChip('🛒  Mall', Icons.shopping_bag_rounded),
                ],
              ),
            ],
          ),
        );
      }
      // Show recent searches
      return ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: _primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          ..._recentSearches.map((recent) => _buildResultTile(
                icon: Icons.access_time_rounded,
                iconBg: _primaryGreen.withOpacity(0.08),
                iconColor: _primaryGreen,
                mainText: recent['name'] ?? '',
                secondaryText: recent['address'] ?? '',
                onTap: () => _selectRecentSearch(recent),
                isRecent: true,
              )),
        ],
      );
    }

    // Loading state
    if (_isSearchingPlaces && _placePredictions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: _primaryGreen,
                backgroundColor: _primaryGreen.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Searching places...',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // No results
    if (_placePredictions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade50,
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  size: 32,
                  color: Colors.red.shade300,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Try a different search for\n"${_searchController.text.trim()}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Prediction results
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: _placePredictions.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    size: 16,
                    color: Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_placePredictions.length} places found',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
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

  Widget _buildSuggestionChip(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        // Extract just the text part after emoji
        final query = label.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        _searchController.text = query;
        _onSearchChanged(query);
        _searchFocusNode.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _primaryGreen.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: _navyDark.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildResultTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String mainText,
    required String secondaryText,
    required VoidCallback onTap,
    bool isRecent = false,
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
          highlightColor: _primaryGreen.withOpacity(0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _navyDark.withOpacity(0.04)),
              boxShadow: [
                BoxShadow(
                  color: _navyDark.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mainText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      if (secondaryText.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          secondaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Trailing arrow
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryGreen.withOpacity(0.08),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _primaryGreen,
                    size: 14,
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
          if (index == 2 && isDriver) {
            _loadActiveRide();
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

// ── Passenger Confirm Bottom Sheet ──

/// Bottom sheet that allows a passenger to confirm joining a ride.
/// Shows their route, distance, and calls the confirm API which returns
/// the cost-split breakdown.
class _PassengerConfirmSheet extends StatefulWidget {
  final String pickupAddress;
  final String dropAddress;
  final double distanceKm;
  final LatLng pickupLatLng;
  final LatLng dropLatLng;
  final UserProfile? userProfile;

  const _PassengerConfirmSheet({
    required this.pickupAddress,
    required this.dropAddress,
    required this.distanceKm,
    required this.pickupLatLng,
    required this.dropLatLng,
    this.userProfile,
  });

  @override
  State<_PassengerConfirmSheet> createState() => _PassengerConfirmSheetState();
}

class _PassengerConfirmSheetState extends State<_PassengerConfirmSheet> {
  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);

  void _findRides() {
    Navigator.pop(context); // close sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AvailableRidesScreen(
          pickupAddress: widget.pickupAddress,
          dropAddress: widget.dropAddress,
          distanceKm: widget.distanceKm,
          pickupLatLng: widget.pickupLatLng,
          dropLatLng: widget.dropLatLng,
          userProfile: widget.userProfile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFF0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Find a Ride',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 20),

              // Route info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accent.withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    _buildRouteRow(
                      Icons.radio_button_checked,
                      _accent,
                      'FROM',
                      widget.pickupAddress,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Container(
                        width: 2,
                        height: 20,
                        color: _accent.withOpacity(0.2),
                      ),
                    ),
                    _buildRouteRow(
                      Icons.location_on,
                      Colors.red.shade400,
                      'TO',
                      widget.dropAddress,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.straighten,
                                  size: 14, color: _accent),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.distanceKm.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Find Rides button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _findRides,
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text(
                    'Find Available Rides',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Browse available rides heading your way',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteRow(
      IconData icon, Color iconColor, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black38,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF040F1B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Dotted line painter for the PICKUP→DROP connector ──

class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter({this.color = Colors.grey});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashHeight = 3.0;
    const dashSpace = 4.0;
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
