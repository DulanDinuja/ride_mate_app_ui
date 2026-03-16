import 'dart:math' as math;

import 'package:flutter/material.dart';

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
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                  children: [
                    TextSpan(text: 'LKR ', style: TextStyle(color: _accent)),
                    TextSpan(text: '1540.00', style: TextStyle(color: Color(0xFF02132A))),
                  ],
                ),
              ),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Location',
                        style: TextStyle(
                          fontSize: 19,
                          color: Color(0xFFA4A6AA),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '158/23, Danny Hettiarachchi\nMawatha',
                        style: TextStyle(
                          fontSize: 43 / 2,
                          height: 1.2,
                          color: Color(0xFF101A2C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 16),
                      Divider(color: Color(0xFFC8CAC1), thickness: 2),
                      SizedBox(height: 16),
                      Text(
                        'Destination',
                        style: TextStyle(
                          fontSize: 19,
                          color: Color(0xFFA4A6AA),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '57 Ramakrishna Rd, Colombo,\n00600',
                        style: TextStyle(
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
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () {},
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
          ],
        ),
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
      canvas.drawLine(Offset(0, y), Offset(size.width, y + random.nextDouble() * 28 - 14), minorRoad);
    }
    for (var i = 0; i < 12; i++) {
      final x = (size.width / 12) * i + random.nextDouble() * 20;
      canvas.drawLine(Offset(x, 0), Offset(x + random.nextDouble() * 30 - 15, size.height), minorRoad);
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
        ..quadraticBezierTo(size.width * 0.2, size.height * 0.22, size.width * 0.14, size.height * 0.48)
        ..quadraticBezierTo(size.width * 0.04, size.height * 0.78, size.width * 0.1, size.height),
      water,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.72, 0)
        ..quadraticBezierTo(size.width * 0.62, size.height * 0.3, size.width * 0.7, size.height * 0.58)
        ..quadraticBezierTo(size.width * 0.8, size.height * 0.8, size.width * 0.74, size.height),
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

