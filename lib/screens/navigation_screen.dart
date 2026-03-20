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
import '../widgets/custom_back_button.dart';

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
  final double rideCost;

  const NavigationArgs({
    required this.origin,
    required this.destination,
    required this.originAddress,
    required this.destAddress,
    required this.polylinePoints,
    required this.distanceKm,
    required this.duration,
    required this.rideId,
    required this.rideCost,
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

  // ── navigation steps ────────────────────────────────────────────
  List<_NavStep> _steps = [];
  int _currentStepIndex = 0;
  bool _loadingSteps = true;

  // ── arrival ─────────────────────────────────────────────────────
  bool _hasArrived = false;
  bool _isCompletingRide = false;

  // ── driver marker icon ──────────────────────────────────────────
  BitmapDescriptor? _driverIcon;



  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LIFECYCLE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  void initState() {
    super.initState();
    _fullPolylinePoints = List<LatLng>.from(widget.args.polylinePoints);
    _remainingPolyline = List<LatLng>.from(_fullPolylinePoints);
    _driverLatLng = widget.args.origin;

    _createDriverIcon();
    _fetchSteps();
    _startLocationStream();
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

    // b) Trim polyline — find closest point and split
    final closestIdx = _findClosestPolylineIndex(latLng, _remainingPolyline);
    final travelled = <LatLng>[
      ..._travelledPolyline,
      if (closestIdx > 0) ..._remainingPolyline.sublist(0, closestIdx),
    ];
    final remaining = closestIdx < _remainingPolyline.length
        ? [latLng, ..._remainingPolyline.sublist(closestIdx)]
        : [latLng];

    if (!mounted) return;
    setState(() {
      _previousLatLng = _driverLatLng;
      _driverLatLng = latLng;
      _bearing = newBearing;
      _travelledPolyline = travelled;
      _remainingPolyline = remaining;
    });

    // f) Animate camera to follow driver
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

          // ── Top instruction banner ──
          SafeArea(
            child: _buildInstructionBanner(),
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
          CustomBackButton(
            onPressed: () => Navigator.pop(context),
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
