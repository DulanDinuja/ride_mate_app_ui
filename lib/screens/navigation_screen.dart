import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../services/api_client.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NavigationArgs — shared by driver & passenger
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class NavigationArgs {
  final LatLng origin;
  final LatLng destination;
  final String originAddress;
  final String destAddress;
  final List<LatLng> polylinePoints;
  final double distanceKm;
  final String duration;
  final int rideId;

  const NavigationArgs({
    required this.origin,
    required this.destination,
    required this.originAddress,
    required this.destAddress,
    required this.polylinePoints,
    required this.distanceKm,
    required this.duration,
    required this.rideId,
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NavigationScreen — shared by driver & passenger
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class NavigationScreen extends StatefulWidget {
  final NavigationArgs args;
  const NavigationScreen({super.key, required this.args});

  @override
  State<NavigationScreen> createState() =>
      _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with TickerProviderStateMixin {
  // ── constants ────────────────────────────────────────────────────
  static const String _gMapsKey = 'AIzaSyAaIKIFaESxfhuchdlrRRQh7r6y9UhU9Uo';
  static const Color _green = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _primaryGreen = Color(0xFF169F7E);

  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d1f24"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a8f98"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1d1f24"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#3a3f48"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#525861"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#5f6670"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f2a36"}]}
]
''';

  // ── map controller ──────────────────────────────────────────────
  GoogleMapController? _mapController;

  // ── live location state ─────────────────────────────────────────
  StreamSubscription<Position>? _locationSubscription;
  LatLng? _driverLatLng;
  double _bearing = 0.0;
  LatLng? _previousLatLng;

  // ── polyline state ──────────────────────────────────────────────
  late List<LatLng> _fullPolylinePoints;
  List<LatLng> _remainingPolyline = [];
  List<LatLng> _travelledPolyline = [];

  // ── live HUD state ──────────────────────────────────────────────
  double _remainingDistanceKm = 0.0;
  String _remainingDuration = '';
  double _currentSpeedKmh = 0.0;

  // ── navigation steps ────────────────────────────────────────────
  List<_NavStep> _steps = [];
  int _currentStepIndex = 0;
  bool _loadingSteps = true;

  // ── arrival ─────────────────────────────────────────────────────
  bool _hasArrived = false;
  bool _isCompletingRide = false;

  // ── driver marker icon ──────────────────────────────────────────
  BitmapDescriptor? _driverIcon;

  // ── camera follow toggle ────────────────────────────────────────
  bool _followDriver = true;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LIFECYCLE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  void initState() {
    super.initState();
    _fullPolylinePoints = List<LatLng>.from(widget.args.polylinePoints);
    _remainingPolyline = List<LatLng>.from(_fullPolylinePoints);
    _remainingDistanceKm = widget.args.distanceKm;
    _remainingDuration = widget.args.duration;
    _driverLatLng = widget.args.origin;

    _createDriverIcon();
    _startLocationStream();
    _fetchSteps();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 1. LIVE LOCATION STREAM
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _startLocationStream() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen(_onLocationUpdate);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 2. ON LOCATION UPDATE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _onLocationUpdate(Position position) {
    if (!mounted || _hasArrived) return;

    final latLng = LatLng(position.latitude, position.longitude);

    // a) Calculate bearing from previous position
    double newBearing = _bearing;
    if (_previousLatLng != null) {
      newBearing = Geolocator.bearingBetween(
        _previousLatLng!.latitude,
        _previousLatLng!.longitude,
        latLng.latitude,
        latLng.longitude,
      );
    }

    // b) Speed (m/s → km/h)
    final speedKmh = (position.speed > 0 ? position.speed : 0.0) * 3.6;

    // c) Trim polyline — find closest point and split
    final closestIdx = _findClosestPolylineIndex(latLng, _remainingPolyline);
    final travelled = <LatLng>[
      ..._travelledPolyline,
      if (closestIdx > 0) ..._remainingPolyline.sublist(0, closestIdx),
    ];
    final remaining = closestIdx < _remainingPolyline.length
        ? [latLng, ..._remainingPolyline.sublist(closestIdx)]
        : [latLng];

    // d) Recalculate remaining distance
    final remDist = _computePolylineDistance(remaining);

    // e) Estimate remaining duration
    final avgSpeed = speedKmh > 5 ? speedKmh : 30.0;
    final etaMinutes = (remDist / avgSpeed) * 60;
    final etaStr = _formatDuration(etaMinutes);

    if (!mounted) return;
    setState(() {
      _previousLatLng = _driverLatLng;
      _driverLatLng = latLng;
      _bearing = newBearing;
      _currentSpeedKmh = speedKmh;
      _travelledPolyline = travelled;
      _remainingPolyline = remaining;
      _remainingDistanceKm = remDist;
      _remainingDuration = etaStr;
    });

    // f) Animate camera to follow driver (Google Maps nav style)
    if (_followDriver) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: latLng,
            zoom: 18.5,
            bearing: newBearing,
            tilt: 60,
          ),
        ),
      );
    }

    // g) Update navigation step
    _updateCurrentStep(latLng);

    // h) Check arrival
    _checkArrival(latLng);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3. DRIVER MARKER — custom rotating arrow icon
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _createDriverIcon() async {
    const double size = 120;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = const Offset(size / 2, size / 2);

    // Outer glow
    canvas.drawCircle(
      center,
      size / 2,
      Paint()
        ..color = _green.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Outer ring
    canvas.drawCircle(
      center,
      size * 0.35,
      Paint()..color = _green.withOpacity(0.2),
    );

    // Inner circle
    canvas.drawCircle(
      center,
      size * 0.25,
      Paint()..color = _green,
    );

    // Arrow pointer
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(size / 2, size * 0.18)
      ..lineTo(size / 2 - 10, size * 0.38)
      ..lineTo(size / 2, size * 0.32)
      ..lineTo(size / 2 + 10, size * 0.38)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null && mounted) {
      final icon = BitmapDescriptor.bytes(
        byteData.buffer.asUint8List(),
        width: 48,
        height: 48,
      );
      setState(() => _driverIcon = icon);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 5. POLYLINE TRIMMING HELPERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  int _findClosestPolylineIndex(LatLng pos, List<LatLng> polyline) {
    if (polyline.isEmpty) return 0;
    int closest = 0;
    double minDist = double.infinity;
    for (int i = 0; i < polyline.length; i++) {
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        polyline[i].latitude,
        polyline[i].longitude,
      );
      if (d < minDist) {
        minDist = d;
        closest = i;
      }
    }
    return closest;
  }

  double _computePolylineDistance(List<LatLng> points) {
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += Geolocator.distanceBetween(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return total / 1000.0;
  }

  String _formatDuration(double minutes) {
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '${minutes.round()} min';
    final h = (minutes / 60).floor();
    final m = (minutes % 60).round();
    return m > 0 ? '$h h $m min' : '$h h';
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // NAVIGATION STEPS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _updateCurrentStep(LatLng current) {
    if (_steps.isEmpty) return;
    for (int i = _currentStepIndex; i < _steps.length; i++) {
      final dist = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        _steps[i].endLocation.latitude,
        _steps[i].endLocation.longitude,
      );
      if (dist < 50 && i + 1 < _steps.length) {
        if (mounted) setState(() => _currentStepIndex = i + 1);
        break;
      }
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 7. ARRIVAL DETECTION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _checkArrival(LatLng current) {
    final dist = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      widget.args.destination.latitude,
      widget.args.destination.longitude,
    );
    if (dist < 50 && !_hasArrived) {
      _locationSubscription?.cancel();
      if (mounted) setState(() => _hasArrived = true);
    }
  }

  Future<void> _completeRide() async {
    if (_isCompletingRide) return;
    setState(() => _isCompletingRide = true);
    try {
      await ApiClient.put(
        '/ride-details/${widget.args.rideId}/complete',
        body: {'status': 'COMPLETED'},
      );
    } catch (_) {
      // Best-effort — always pop back
    }
    if (mounted) Navigator.pop(context, true);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // FETCH DIRECTIONS STEPS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _fetchSteps() async {
    if (mounted) setState(() => _loadingSteps = true);
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${widget.args.origin.latitude},${widget.args.origin.longitude}'
        '&destination=${widget.args.destination.latitude},${widget.args.destination.longitude}'
        '&mode=driving&key=$_gMapsKey',
      );
      final resp = await http.get(url);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['status'] == 'OK') {
          final rawSteps = data['routes'][0]['legs'][0]['steps'] as List;
          setState(() {
            _steps = rawSteps.map((s) {
              final endLoc = s['end_location'];
              return _NavStep(
                instruction: _stripHtml(s['html_instructions'] as String),
                distance: s['distance']['text'] as String,
                endLocation: LatLng(
                  (endLoc['lat'] as num).toDouble(),
                  (endLoc['lng'] as num).toDouble(),
                ),
                maneuver: s['maneuver'] as String? ?? '',
              );
            }).toList();
            _loadingSteps = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingSteps = false);
  }

  String _stripHtml(String html) =>
      html
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  IconData _maneuverIcon(String maneuver) {
    if (maneuver.contains('left')) return Icons.turn_left_rounded;
    if (maneuver.contains('right')) return Icons.turn_right_rounded;
    if (maneuver.contains('uturn')) return Icons.u_turn_left_rounded;
    if (maneuver.contains('roundabout')) return Icons.roundabout_left_rounded;
    return Icons.straight_rounded;
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
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // BUILD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Widget build(BuildContext context) {
    // ── Markers ──
    final markers = <Marker>{
      // Destination marker
      Marker(
        markerId: const MarkerId('dest'),
        position: widget.args.destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.args.destAddress),
      ),
      // Driver marker — custom rotating arrow
      if (_driverLatLng != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLatLng!,
          icon: _driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          rotation: _bearing,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 10,
        ),
    };

    // ── Polylines ──
    final polylines = <Polyline>{
      // Travelled portion (faded grey)
      if (_travelledPolyline.length >= 2)
        Polyline(
          polylineId: const PolylineId('travelled'),
          points: _travelledPolyline,
          color: Colors.white.withOpacity(0.25),
          width: 5,
        ),
      // Remaining route (green)
      if (_remainingPolyline.length >= 2)
        Polyline(
          polylineId: const PolylineId('remaining'),
          points: _remainingPolyline,
          color: _green,
          width: 6,
        ),
    };

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ──
          GoogleMap(
            onMapCreated: (c) {
              _mapController = c;
              c.setMapStyle(_darkMapStyle).catchError((_) {});
              // Initial zoom to show full route
              final bounds = _boundsFromLatLngs([
                widget.args.origin,
                widget.args.destination,
                ...widget.args.polylinePoints,
              ]);
              Future.delayed(const Duration(milliseconds: 400), () {
                c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
              });
              // Transition to nav view after 2.5s
              Future.delayed(const Duration(milliseconds: 2500), () {
                if (mounted && _driverLatLng != null && _followDriver) {
                  c.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _driverLatLng!,
                        zoom: 18.5,
                        bearing: _bearing,
                        tilt: 60,
                      ),
                    ),
                  );
                }
              });
            },
            initialCameraPosition: CameraPosition(
              target: widget.args.origin,
              zoom: 15,
            ),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            markers: markers,
            polylines: polylines,
          ),

          // ── Top instruction + bottom HUD ──
          SafeArea(
            child: Column(
              children: [
                _buildInstructionBanner(),
                const Spacer(),
                _buildLiveHudPanel(),
              ],
            ),
          ),

          // ── Re-center button ──
          Positioned(
            right: 16,
            bottom: 230,
            child: _buildRecenterButton(),
          ),

          // ── Arrived overlay ──
          if (_hasArrived) _buildArrivedOverlay(),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // INSTRUCTION BANNER (top)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildInstructionBanner() {
    final step = (_steps.isNotEmpty && _currentStepIndex < _steps.length)
        ? _steps[_currentStepIndex]
        : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _navy.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          if (_loadingSteps)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _green),
            )
          else if (step != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(_maneuverIcon(step.maneuver), color: _green, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.instruction,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    step.distance,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const Expanded(
              child: Text(
                'Head to destination',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 6. LIVE HUD — bottom info panel
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildLiveHudPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _navy.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Live stats row ──
          Row(
            children: [
              _buildLiveStatCard(
                icon: Icons.route_rounded,
                value: _remainingDistanceKm < 1
                    ? '${(_remainingDistanceKm * 1000).round()} m'
                    : '${_remainingDistanceKm.toStringAsFixed(1)} km',
                label: 'Distance',
                color: _green,
              ),
              const SizedBox(width: 8),
              _buildLiveStatCard(
                icon: Icons.access_time_filled_rounded,
                value: _remainingDuration,
                label: 'ETA',
                color: const Color(0xFFFF6B35),
              ),
              const SizedBox(width: 8),
              _buildLiveStatCard(
                icon: Icons.speed_rounded,
                value: '${_currentSpeedKmh.round()}',
                label: 'km/h',
                color: _primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Destination row ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: Colors.redAccent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Destination',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.args.destAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _green.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _green,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live',
                        style: TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Step chips ──
          if (_steps.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _steps.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final active = i == _currentStepIndex;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? _green.withOpacity(0.2)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active
                            ? _green.withOpacity(0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _maneuverIcon(_steps[i].maneuver),
                          color: active ? _green : Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _steps[i].distance,
                          style: TextStyle(
                            color: active ? _green : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Re-center button ──
  Widget _buildRecenterButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _followDriver = true);
        if (_driverLatLng != null) {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _driverLatLng!,
                zoom: 18.5,
                bearing: _bearing,
                tilt: 60,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _navy.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.my_location_rounded, color: _green, size: 22),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ARRIVED OVERLAY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildArrivedOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _green.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: _green, size: 50),
                ),
                const SizedBox(height: 20),
                const Text(
                  'You have arrived!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.args.destAddress,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                // Trip summary
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildArrivalStat(
                        Icons.route_rounded,
                        '${widget.args.distanceKm.toStringAsFixed(1)} km',
                        'Total',
                      ),
                      Container(
                          width: 1, height: 30, color: Colors.white12),
                      _buildArrivalStat(
                        Icons.access_time_rounded,
                        widget.args.duration,
                        'Duration',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isCompletingRide ? null : _completeRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      disabledBackgroundColor: _green.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isCompletingRide
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Complete Ride',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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

  Widget _buildArrivalStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: _green, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Navigation step model
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _NavStep {
  final String instruction;
  final String distance;
  final LatLng endLocation;
  final String maneuver;

  const _NavStep({
    required this.instruction,
    required this.distance,
    required this.endLocation,
    required this.maneuver,
  });
}
