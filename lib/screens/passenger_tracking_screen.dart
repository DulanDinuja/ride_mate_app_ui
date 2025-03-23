import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/driver_location_update.dart';
import '../services/location_tracking_service.dart';
import '../services/stomp_service.dart';
import '../widgets/custom_back_button.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PassengerTrackingArgs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class PassengerTrackingArgs {
  final int rideDetailId;
  final String pickupAddress;
  final String dropAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final String? driverName;
  final String? vehicleInfo;

  const PassengerTrackingArgs({
    required this.rideDetailId,
    required this.pickupAddress,
    required this.dropAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.driverName,
    this.vehicleInfo,
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PassengerTrackingScreen — live map showing driver's location
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class PassengerTrackingScreen extends StatefulWidget {
  final PassengerTrackingArgs args;

  const PassengerTrackingScreen({super.key, required this.args});

  @override
  State<PassengerTrackingScreen> createState() =>
      _PassengerTrackingScreenState();
}

class _PassengerTrackingScreenState extends State<PassengerTrackingScreen> {
  // ── Colours ─────────────────────────────────────────────────────
  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);

  // ── Map ─────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  BitmapDescriptor? _driverIcon;
  LatLng? _driverLatLng;
  double _driverBearing = 0.0;

  // ── WebSocket subscription ──────────────────────────────────────
  StompUnsubscribeHandle? _locationSub;
  bool _isConnecting = true;
  String? _connectionError;
  DateTime? _lastUpdate;

  // ── Stale-check timer ───────────────────────────────────────────
  Timer? _staleTimer;
  bool _isStale = false;

  @override
  void initState() {
    super.initState();
    _createDriverIcon();
    _initTracking();
    _staleTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_lastUpdate != null && mounted) {
        final diff = DateTime.now().difference(_lastUpdate!);
        setState(() => _isStale = diff.inSeconds > 15);
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.unsubscribe();
    LocationTrackingService.stopTracking();
    _staleTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // INIT — fetch initial location, then open WebSocket
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _initTracking() async {
    try {
      // 1. Fetch initial cached location via REST
      final initial = await LocationTrackingService.getLatestDriverLocation(
        widget.args.rideDetailId,
      );
      if (initial != null && mounted) {
        setState(() {
          _driverLatLng = LatLng(initial.latitude, initial.longitude);
          _driverBearing = initial.bearing;
          _lastUpdate = DateTime.fromMillisecondsSinceEpoch(initial.timestamp);
        });
        _animateToDriver();
      }

      // 2. Open WebSocket
      await LocationTrackingService.startTracking(
        rideId: widget.args.rideDetailId,
      );

      // 3. Subscribe to live updates
      _locationSub = LocationTrackingService.subscribeToDriverLocation(
        rideId: widget.args.rideDetailId,
        onUpdate: _onDriverLocationUpdate,
      );

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectionError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectionError = 'Could not connect to live tracking: $e';
        });
      }
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ON DRIVER LOCATION UPDATE (from WebSocket)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _onDriverLocationUpdate(DriverLocationUpdate update) {
    if (!mounted) return;
    setState(() {
      _driverLatLng = LatLng(update.latitude, update.longitude);
      _driverBearing = update.bearing;
      _lastUpdate = DateTime.now();
      _isStale = false;
    });
    _animateToDriver();
  }

  void _animateToDriver() {
    if (_driverLatLng == null || _mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _driverLatLng!,
          zoom: 16,
          bearing: _driverBearing,
          tilt: 45,
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DRIVER MARKER ICON
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
        ..color = _accent.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Outer ring
    canvas.drawCircle(
      center,
      size * 0.35,
      Paint()..color = _accent.withOpacity(0.25),
    );

    // Inner circle
    canvas.drawCircle(
      center,
      size * 0.22,
      Paint()..color = _accent,
    );

    // Car icon (simple arrow)
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
  // BUILD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Widget build(BuildContext context) {
    final pickupLatLng = widget.args.pickupLat != null &&
            widget.args.pickupLng != null
        ? LatLng(widget.args.pickupLat!, widget.args.pickupLng!)
        : null;
    final dropLatLng = widget.args.dropLat != null &&
            widget.args.dropLng != null
        ? LatLng(widget.args.dropLat!, widget.args.dropLng!)
        : null;

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _driverLatLng ?? pickupLatLng ?? const LatLng(6.9271, 79.8612),
              zoom: 15,
              tilt: 45,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_driverLatLng != null) _animateToDriver();
            },
            markers: _buildMarkers(pickupLatLng, dropLatLng),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // ── Top bar ─────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CustomBackButton(onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_taxi,
                              color: _accent, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Tracking Driver',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _navy,
                              ),
                            ),
                          ),
                          // Live indicator
                          _buildLiveIndicator(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom info card ─────────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: _buildBottomCard(),
          ),

          // ── Connecting overlay ───────────────────────────────────
          if (_isConnecting)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _accent),
                    SizedBox(height: 16),
                    Text(
                      'Connecting to live tracking...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.white,
        onPressed: _animateToDriver,
        child: const Icon(Icons.my_location, color: _accent),
      ),
    );
  }

  // ─── Markers ─────────────────────────────────────────────────────

  Set<Marker> _buildMarkers(LatLng? pickup, LatLng? drop) {
    final markers = <Marker>{};

    // Driver marker
    if (_driverLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLatLng!,
          rotation: _driverBearing,
          anchor: const Offset(0.5, 0.5),
          icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: widget.args.driverName ?? 'Driver',
            snippet: widget.args.vehicleInfo,
          ),
          flat: true,
        ),
      );
    }

    // Pickup marker
    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: 'Pickup', snippet: widget.args.pickupAddress),
        ),
      );
    }

    // Drop marker
    if (drop != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: drop,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Drop-off', snippet: widget.args.dropAddress),
        ),
      );
    }

    return markers;
  }

  // ─── Live indicator dot ──────────────────────────────────────────

  Widget _buildLiveIndicator() {
    final Color dotColor;
    final String label;

    if (_connectionError != null) {
      dotColor = Colors.red;
      label = 'Offline';
    } else if (_isStale) {
      dotColor = Colors.orange;
      label = 'Waiting...';
    } else if (_isConnecting) {
      dotColor = Colors.orange;
      label = 'Connecting';
    } else {
      dotColor = _accent;
      label = 'Live';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: dotColor.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: dotColor,
          ),
        ),
      ],
    );
  }

  // ─── Bottom info card ────────────────────────────────────────────

  Widget _buildBottomCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver info row
          if (widget.args.driverName != null || widget.args.vehicleInfo != null)
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _accent.withOpacity(0.12),
                  child: const Icon(Icons.person, color: _accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.args.driverName != null)
                        Text(
                          widget.args.driverName!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                      if (widget.args.vehicleInfo != null)
                        Text(
                          widget.args.vehicleInfo!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildLiveIndicator(),
              ],
            ),
          if (widget.args.driverName != null || widget.args.vehicleInfo != null)
            const Divider(height: 24),

          // Route
          Row(
            children: [
              Icon(Icons.radio_button_checked,
                  size: 16, color: Colors.blue.shade400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.args.pickupAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _navy,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Container(width: 2, height: 14, color: Colors.grey.shade300),
          ),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.red.shade400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.args.dropAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _navy,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Ride ID
          Center(
            child: Text(
              'Ride #${widget.args.rideDetailId}',
              style: const TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ),

          // Connection error message
          if (_connectionError != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.red.shade400, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live tracking unavailable. Retrying...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isConnecting = true;
                        _connectionError = null;
                      });
                      _initTracking();
                    },
                    child: Icon(Icons.refresh,
                        color: Colors.red.shade400, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

