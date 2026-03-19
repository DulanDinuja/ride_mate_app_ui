import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
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
  bool _isChangingRole = false;
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

  // ── route ──
  Set<Polyline> _polylines = {};
  double? _routeDistanceKm;
  String? _routeDuration;
  bool _isFetchingRoute = false;

  // ── search mode ──
  bool _isSearchMode = false;
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
      if (address != _coordString(latLng)) {
        setState(() => _pickupAddress = address);
      }
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

    // ── Method 2: Google Geocoding REST API ──
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${latLng.latitude},${latLng.longitude}'
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

    // ── Method 3: OpenStreetMap Nominatim (free, no API key, works everywhere) ──
    try {
      final nominatimUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${latLng.latitude}&lon=${latLng.longitude}'
        '&format=json&zoom=16&addressdetails=1',
      );
      final resp = await http.get(nominatimUrl, headers: {
        'User-Agent': 'RideMateApp/1.0',
        'Accept-Language': 'en',
      });
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Ride confirmed! Looking for drivers...'),
      backgroundColor: Color(0xFF03AF74),
    ));
  }

  Future<void> _fetchRoute() async {
    final origin = _pickupLatLng;
    final destination = _dropLatLng;
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

          // Fit camera to show full route
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
                patterns: [],
              ),
            };
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[Route] Directions API error: $e');
    }

    // Fallback: straight-line distance
    if (mounted) {
      final distM = Geolocator.distanceBetween(
        origin.latitude, origin.longitude,
        destination.latitude, destination.longitude,
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
    int index = 0;
    int lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
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

  // ── search helpers ──────────────────────────────────────────────

  void _openSearchMode() {
    setState(() {
      _isSearchMode = true;
      _searchController.clear();
      _placePredictions = [];
      _dropLatLng = null;
      _dropAddress = '';
      _dropController.clear();
      _polylines = {};
      _routeDistanceKm = null;
      _routeDuration = null;
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
        if (data['status'] == 'OK') {
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
        }
      }
    } catch (e) {
      debugPrint('[Places] Google Autocomplete error: $e');
    }

    // ── Fallback: Photon API (autocomplete-friendly, CORS-safe, works on web) ──
    try {
      debugPrint('[Places] Trying Photon for "$input"');
      final loc = _pickupLatLng ?? _defaultCenter;
      final url = Uri.parse(
        'https://photon.komoot.io/api/'
        '?q=${Uri.encodeComponent(input)}'
        '&limit=10'
        '&lang=en'
        '&lat=${loc.latitude}'
        '&lon=${loc.longitude}',
      );
      final resp = await http.get(url);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final features = (data['features'] as List?) ?? [];
        debugPrint('[Places] Photon returned ${features.length} results');

        // Prefer Sri Lanka results, but show all if none match
        final sriLankaResults = features.where((f) {
          final country =
              (f['properties'] as Map<String, dynamic>?)?['country'] as String?;
          return country != null &&
              country.toLowerCase().contains('sri lanka');
        }).toList();

        final resultsToUse =
            sriLankaResults.isNotEmpty ? sriLankaResults : features;

        setState(() {
          _placePredictions =
              resultsToUse.take(7).map<Map<String, dynamic>>((f) {
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

    _closeSearchMode();
    setState(() => _isSearchingDrop = true);

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
      setState(() {
        _dropLatLng = latLng;
        _dropAddress = mainText;
        _dropController.text = mainText;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      _fetchRoute();

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

  Future<void> _onChangeRole() async {
    final profile = _userProfile;
    if (profile == null) return;

    final userId = await TokenService.getUserId();
    if (userId == null) return;

    final isPassenger = profile.role.toUpperCase() == 'PASSENGER';
    final newRole = isPassenger ? 'DRIVER' : 'PASSENGER';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPassenger ? 'Become a Driver?' : 'Switch to Passenger?'),
        content: Text(
          isPassenger
              ? 'You will need to complete your driver profile with vehicle details, photos, driving licence, insurance and revenue licence.'
              : 'Switch your role back to Passenger?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isPassenger ? 'Continue' : 'Confirm'),
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
        // Launch the full driver registration flow
        Navigator.pushNamed(context, AppRoutes.vehicleRegistration);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role changed to Passenger.'),
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
                trailing: _isChangingRole
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch(
                        value: (profile?.role.toUpperCase() ?? '') == 'DRIVER',
                        activeColor: const Color(0xFF03AF74),
                        onChanged: profile == null || _isChangingRole
                            ? null
                            : (_) => _onChangeRole(),
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
              c.setMapStyle(_darkMapStyle).catchError((_) {});
              if (_pickupLatLng != null) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted && _pickupLatLng != null) {
                    c.animateCamera(CameraUpdate.newLatLngZoom(_pickupLatLng!, 16));
                  }
                });
              }
            },
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
          ),
          _buildRidePanel(),
          if (_isLocating)
            _buildBanner('Getting your current location...', Colors.black87),
          if (!_isLocating && _locationError != null)
            _buildErrorBanner(_locationError!),
          if (_showDriverProfileCard) _buildCompleteDriverProfileCard(),
          if (_isSearchMode) _buildSearchOverlay(),
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
                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (_pickupLatLng != null && _dropLatLng != null) ? _onConfirm : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF03AF74),
                            disabledBackgroundColor: const Color(0xFF03AF74).withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 20),
                            onPressed: _closeSearchMode,
                            splashRadius: 22,
                          ),
                          const Expanded(
                            child: Text(
                              'Set Destination',
                              textAlign: TextAlign.center,
                              style: TextStyle(
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
                                    Container(
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
                                    // ── Drop row (text field) ──
                                    Container(
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
