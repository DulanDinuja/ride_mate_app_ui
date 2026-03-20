import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/routes/app_routes.dart';
import '../models/user_profile.dart';
import '../services/driver_service.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_back_button.dart';
import 'navigation_screen.dart';
import 'ride_requests_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Arguments passed to this screen from the driver offer-ride flow.
class RideStartArgs {
  final int rideDetailId;
  final int? driverProfileId;
  final String pickupAddress;
  final String dropAddress;
  final double totalCost;
  final double distanceKm;
  final double perKmRate;
  final String? duration;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final List<LatLng>? polylinePoints;

  const RideStartArgs({
    required this.rideDetailId,
    this.driverProfileId,
    required this.pickupAddress,
    required this.dropAddress,
    required this.totalCost,
    required this.distanceKm,
    required this.perKmRate,
    this.duration,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.polylinePoints,
  });
}

class RideStartScreen extends StatefulWidget {
  const RideStartScreen({super.key});

  @override
  State<RideStartScreen> createState() => _RideStartScreenState();
}

class _RideStartScreenState extends State<RideStartScreen> {
  bool _isDriverMode = true; // true = Offer Ride, false = Request Ride
  bool _showTripCard = true;
  bool _isChangingRole = false;
  bool _tripStarted = false;

  static const Color _cardBackground = Color(0xFFFFFFF0);
  static const Color _accent = Color(0xFF10B47A);
  static const Color _navy = Color(0xFF02132A);

  RideStartArgs? _args;
  UserProfile? _userProfile;

  /// Opens Google Maps with directions from pickup to drop location.
  Future<void> _openGoogleMaps() async {
    if (_args == null) return;

    final pickupLat = _args!.pickupLat;
    final pickupLng = _args!.pickupLng;
    final dropLat = _args!.dropLat;
    final dropLng = _args!.dropLng;

    if (pickupLat == null || pickupLng == null || dropLat == null || dropLng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location coordinates are not available.')),
        );
      }
      return;
    }

    // Try native Google Maps app first, fall back to web
    final googleMapsUrl = Uri.parse(
      'comgooglemaps://?saddr=$pickupLat,$pickupLng&daddr=$dropLat,$dropLng&directionsmode=driving',
    );
    final webUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$pickupLat,$pickupLng&destination=$dropLat,$dropLng&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Google Maps: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RideStartArgs) {
      _args = args;
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = await TokenService.getUserId();
      if (userId == null) return;
      final profile = await UserService.getUserProfileByUserId(userId);
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _isDriverMode = profile.role.toUpperCase() == 'DRIVER';
      });
    } catch (_) {
      // Profile load failed — keep defaults
    }
  }

  Future<void> _onToggleRole(bool toDriver) async {
    if (_isChangingRole) return;
    if (_userProfile == null) return;

    final currentIsDriver = _userProfile!.role.toUpperCase() == 'DRIVER';
    if (toDriver == currentIsDriver) {
      setState(() => _isDriverMode = toDriver);
      return;
    }

    final userId = await TokenService.getUserId();
    if (userId == null) return;
    if (!mounted) return;

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
      // Reload profile
      final profile = await UserService.getUserProfileByUserId(userId);
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _isDriverMode = toDriver;
      });

      if (toDriver) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RideMapPainter(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomBackButton(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildRideModeSwitcher()),
                      const SizedBox(width: 12),
                      _buildMenuButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_showTripCard)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildTripCard(context),
            ),
        ],
      ),
    );
  }

  Widget _buildRideModeSwitcher() {
    return Container(
      height: 78,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isChangingRole ? null : () => _onToggleRole(true),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isDriverMode ? _accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Offer Ride',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: _isDriverMode ? Colors.white : const Color(0xFFFFFFF0),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _isChangingRole ? null : () => _onToggleRole(false),
                  child: Container(
                    decoration: BoxDecoration(
                      color: !_isDriverMode ? _accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Request Ride',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: !_isDriverMode ? Colors.white : const Color(0xFFFFFFF0),
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
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(32),
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.driverHomeMap);
      },
      child: Container(
        width: 78,
        height: 78,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _navy,
        ),
        child: const Icon(
          Icons.menu_rounded,
          color: Color(0xFFFFFFF0),
          size: 40,
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context) {
    final pickupAddr = _args?.pickupAddress ?? 'Current Location';
    final dropAddr = _args?.dropAddress ?? 'Destination';
    final totalCost = _args?.totalCost ?? 0;
    final distanceKm = _args?.distanceKm ?? 0;
    final perKmRate = _args?.perKmRate ?? 0;
    final duration = _args?.duration ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      decoration: const BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(44)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                const Text(
                  'TOTAL COST OF THE TRIP',
                  style: TextStyle(
                    color: Color(0xFFA9AAAC),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showTripCard = false),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 38,
                    color: Color(0xFF8C8F8C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E3D8),
                borderRadius: BorderRadius.circular(26),
              ),
              alignment: Alignment.center,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                  children: [
                    const TextSpan(text: 'LKR ', style: TextStyle(color: _accent)),
                    TextSpan(
                      text: totalCost.toStringAsFixed(2),
                      style: const TextStyle(color: Color(0xFF02132A)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Per-km rate + distance + duration info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoChip(Icons.straighten, '${distanceKm.toStringAsFixed(1)} km'),
                const SizedBox(width: 10),
                _buildInfoChip(Icons.speed, 'LKR ${perKmRate.toStringAsFixed(0)}/km'),
                if (duration.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  _buildInfoChip(Icons.access_time_rounded, duration),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(Icons.radio_button_unchecked, color: _navy, size: 32),
                    Container(width: 3, height: 132, color: const Color(0xFF0D7358)),
                    const Icon(Icons.adjust_rounded, color: _accent, size: 34),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Location',
                        style: TextStyle(
                          fontSize: 19,
                          color: Color(0xFFA4A6AA),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pickupAddr,
                        style: const TextStyle(
                          fontSize: 43 / 2,
                          height: 1.2,
                          color: Color(0xFF101A2C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFC8CAC1), thickness: 2),
                      const SizedBox(height: 16),
                      const Text(
                        'Destination',
                        style: TextStyle(
                          fontSize: 19,
                          color: Color(0xFFA4A6AA),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dropAddr,
                        style: const TextStyle(
                          fontSize: 43 / 2,
                          height: 1.2,
                          color: Color(0xFF101A2C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6E7DC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_vert_rounded, color: _accent, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Main action button — Start The Trip / Open with Google Map
            if (!_tripStarted)
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _tripStarted = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text(
                    'Start The Trip',
                    style: TextStyle(fontSize: 42 / 2, fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: _openGoogleMaps,
                  icon: Image.asset(
                    'assets/images/google_maps_icon.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.map_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  label: const Text(
                    'Open with Google Map',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            // View cost split button
            if (_args != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.costSplit,
                      arguments: {
                        'rideDetailId': _args!.rideDetailId,
                        'isDriver': _isDriverMode,
                      },
                    );
                  },
                  icon: const Icon(Icons.pie_chart_outline),
                  label: const Text(
                    'View Cost Split',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _accent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              // View ride requests button (driver only)
              if (_isDriverMode) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.rideRequests,
                        arguments: RideRequestsArgs(
                          rideDetailId: _args!.rideDetailId,
                          totalRideCost: _args!.totalCost,
                        ),
                      );
                    },
                    icon: const Icon(Icons.people_outline),
                    label: const Text(
                      'View Ride Requests',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF02132A),
                      side: const BorderSide(color: Color(0xFF02132A)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _accent),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF02132A),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = const Color(0xFF3B3E45);
    canvas.drawRect(Offset.zero & size, base);

    final road = Paint()
      ..color = const Color(0xFF72757D)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final minorRoad = Paint()
      ..color = const Color(0xFF63666E)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final water = Paint()
      ..color = const Color(0xFF0E4A5E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final park = Paint()..color = const Color(0xFF2D4A12);

    final random = math.Random(7);
    for (var i = 0; i < 18; i++) {
      final y = (size.height / 18) * i + random.nextDouble() * 16;
      canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y + random.nextDouble() * 28 - 14),
          minorRoad);
    }
    for (var i = 0; i < 12; i++) {
      final x = (size.width / 12) * i + random.nextDouble() * 20;
      canvas.drawLine(
          Offset(x, 0),
          Offset(x + random.nextDouble() * 30 - 15, size.height),
          minorRoad);
    }

    canvas.drawPath(
      Path()
        ..moveTo(-20, size.height * 0.3)
        ..lineTo(size.width * 0.45, size.height * 0.38)
        ..lineTo(size.width + 20, size.height * 0.34),
      road,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-20, size.height * 0.55)
        ..lineTo(size.width * 0.38, size.height * 0.52)
        ..lineTo(size.width + 20, size.height * 0.6),
      road,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.06, 0)
        ..quadraticBezierTo(
            size.width * 0.2, size.height * 0.22, size.width * 0.14, size.height * 0.48)
        ..quadraticBezierTo(
            size.width * 0.04, size.height * 0.78, size.width * 0.1, size.height),
      water,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.72, 0)
        ..quadraticBezierTo(
            size.width * 0.62, size.height * 0.3, size.width * 0.7, size.height * 0.58)
        ..quadraticBezierTo(
            size.width * 0.8, size.height * 0.8, size.width * 0.74, size.height),
      water,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.28),
        width: 64,
        height: 52,
      ),
      park,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.62, size.height * 0.78),
        width: 86,
        height: 58,
      ),
      park,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

