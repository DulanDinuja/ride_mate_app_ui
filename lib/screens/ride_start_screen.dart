import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/routes/app_routes.dart';

/// Arguments passed to this screen from the driver offer-ride flow.
class RideStartArgs {
  final int rideDetailId;
  final String pickupAddress;
  final String dropAddress;
  final double totalCost;
  final double distanceKm;
  final double perKmRate;

  const RideStartArgs({
    required this.rideDetailId,
    required this.pickupAddress,
    required this.dropAddress,
    required this.totalCost,
    required this.distanceKm,
    required this.perKmRate,
  });
}

class RideStartScreen extends StatefulWidget {
  const RideStartScreen({super.key});

  @override
  State<RideStartScreen> createState() => _RideStartScreenState();
}

class _RideStartScreenState extends State<RideStartScreen> {
  bool _offerRideSelected = true;
  bool _showTripCard = true;

  static const Color _cardBackground = Color(0xFFFFFFF0);
  static const Color _accent = Color(0xFF10B47A);
  static const Color _navy = Color(0xFF02132A);

  RideStartArgs? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RideStartArgs) {
      _args = args;
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
              child: Row(
                children: [
                  Expanded(child: _buildRideModeSwitcher()),
                  const SizedBox(width: 12),
                  _buildMenuButton(),
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
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _offerRideSelected = true),
              child: Container(
                decoration: BoxDecoration(
                  color: _offerRideSelected ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Offer Ride',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: _offerRideSelected ? Colors.white : const Color(0xFFFFFFF0),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _offerRideSelected = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_offerRideSelected ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Request Ride',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: !_offerRideSelected ? Colors.white : const Color(0xFFFFFFF0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton() {
    return Container(
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
    );
  }

  Widget _buildTripCard(BuildContext context) {
    final pickupAddr = _args?.pickupAddress ?? 'Current Location';
    final dropAddr = _args?.dropAddress ?? 'Destination';
    final totalCost = _args?.totalCost ?? 0;
    final distanceKm = _args?.distanceKm ?? 0;
    final perKmRate = _args?.perKmRate ?? 0;

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
            // Per-km rate + distance info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoChip(Icons.straighten, '${distanceKm.toStringAsFixed(1)} km'),
                const SizedBox(width: 10),
                _buildInfoChip(Icons.speed, 'LKR ${perKmRate.toStringAsFixed(0)}/km'),
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
            // Main action button
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () {
                  if (_args != null) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.activeRide,
                      arguments: {
                        'rideDetailId': _args!.rideDetailId,
                        'pickupAddress': _args!.pickupAddress,
                        'dropAddress': _args!.dropAddress,
                        'totalDistance': _args!.distanceKm,
                        'totalCost': _args!.totalCost,
                      },
                    );
                  }
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
                        'isDriver': true,
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

