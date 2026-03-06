import 'package:flutter/material.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  bool _isOfferRide = true;
  bool _showRideCost = true;

  String _pickupAddress = '158/23, Danny Hettiarachchi Mawatha';
  String _dropOffAddress = '57 Ramakrishna Rd, Colombo, 00600';

  void _swapLocations() {
    setState(() {
      final temp = _pickupAddress;
      _pickupAddress = _dropOffAddress;
      _dropOffAddress = temp;
    });
  }

  void _onStartTheRide() {
    // TODO: Start the ride
  }

  void _onMenuPressed() {
    // TODO: Open drawer/menu
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          _buildMapBackground(),

          // Top Controls
          _buildTopControls(),

          // Bottom Ride Cost Sheet
          if (_showRideCost) _buildRideCostSheet(),
        ],
      ),
    );
  }

  /// Dark map-like background
  Widget _buildMapBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2332),
      ),
      child: CustomPaint(
        painter: _MapPatternPainter(),
        size: Size.infinite,
      ),
    );
  }

  /// Top section: Offer Ride / Request Ride toggle + menu button
  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Row(
          children: [
            // Offer Ride / Request Ride Toggle
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF040F1B),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    // Offer Ride
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isOfferRide = true),
                        child: Container(
                          height: 42,
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _isOfferRide
                                ? const Color(0xFF03AF74)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Center(
                            child: Text(
                              'Offer Ride',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _isOfferRide
                                    ? const Color(0xFFFFFFF0)
                                    : const Color(0xFFFFFFF0).withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Request Ride
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isOfferRide = false),
                        child: Container(
                          height: 42,
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: !_isOfferRide
                                ? const Color(0xFF03AF74)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Center(
                            child: Text(
                              'Request Ride',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: !_isOfferRide
                                    ? const Color(0xFFFFFFF0)
                                    : const Color(0xFFFFFFF0).withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Menu Button
            GestureDetector(
              onTap: _onMenuPressed,
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF040F1B),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMenuLine(),
                    const SizedBox(height: 5),
                    _buildMenuLine(),
                    const SizedBox(height: 5),
                    _buildMenuLine(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuLine() {
    return Container(
      width: 22,
      height: 3,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFF0),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  /// Bottom ride cost sheet
  Widget _buildRideCostSheet() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFF0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Total Cost label + Close button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL COST OF THE TRIP',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB3B3B3),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Cost container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF1E3),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'LKR ',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF03AF74),
                                  ),
                                ),
                                TextSpan(
                                  text: '1540.00',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF040F1B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  GestureDetector(
                    onTap: () => setState(() => _showRideCost = false),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close,
                          color: const Color(0xFF040F1B).withOpacity(0.47),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Pickup & Drop-off section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route indicator (circles + line)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, right: 12.0),
                    child: _buildRouteIndicator(),
                  ),

                  // Location details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pickup
                        const Text(
                          'Pickup',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB3B3B3),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _pickupAddress,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF040F1B),
                            height: 1.33,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Divider line with swap button
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: const Color(0xFFD9D9D9),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Swap button
                            GestureDetector(
                              onTap: _swapLocations,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF1E3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.swap_vert,
                                  color: Color(0xFF03AF74),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Drop Off
                        const Text(
                          'Drop Off',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB3B3B3),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dropOffAddress,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF040F1B),
                            height: 1.33,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Start The Ride Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _onStartTheRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF040F1B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start The Ride',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFF0),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Route indicator: filled dark circle -> gradient line -> green outlined circle
  Widget _buildRouteIndicator() {
    return SizedBox(
      width: 22,
      child: Column(
        children: [
          // Pickup circle (dark filled)
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF040F1B),
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFFFF0),
                ),
              ),
            ),
          ),

          // Gradient line
          Container(
            width: 3,
            height: 90,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF040F1B),
                  Color(0xFF03AF74),
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),

          // Drop-off circle (green outlined)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF03AF74),
                width: 3,
              ),
              color: const Color(0xFFFFFFF0),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF03AF74),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to simulate a detailed dark-themed map pattern
class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    final bgPaint = Paint()..color = const Color(0xFF1E2A36);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Building block fill (slightly lighter than bg)
    final blockPaint = Paint()
      ..color = const Color(0xFF232F3C)
      ..style = PaintingStyle.fill;

    // Draw city blocks (irregular rectangles)
    _drawCityBlocks(canvas, w, h, blockPaint);

    // Water bodies (rivers, canals)
    _drawWaterBodies(canvas, w, h);

    // Park / green areas
    _drawParks(canvas, w, h);

    // Minor roads (thin, subtle)
    final minorRoadPaint = Paint()
      ..color = const Color(0xFF2E3D4D)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Medium roads
    final medRoadPaint = Paint()
      ..color = const Color(0xFF374A5C)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Major roads (wider, brighter)
    final majorRoadPaint = Paint()
      ..color = const Color(0xFF435A6E)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Highway roads
    final highwayPaint = Paint()
      ..color = const Color(0xFF4D6578)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw minor grid (dense street network)
    _drawMinorStreets(canvas, w, h, minorRoadPaint);

    // Draw medium streets
    _drawMediumStreets(canvas, w, h, medRoadPaint);

    // Draw major roads
    _drawMajorRoads(canvas, w, h, majorRoadPaint);

    // Draw highways / arterials
    _drawHighways(canvas, w, h, highwayPaint);

    // Draw diagonal & curved roads
    _drawDiagonalRoads(canvas, w, h, medRoadPaint, majorRoadPaint);

    // Draw roundabouts
    _drawRoundabouts(canvas, w, h);

    // Draw small building details
    _drawBuildingDetails(canvas, w, h);
  }

  void _drawCityBlocks(Canvas canvas, double w, double h, Paint paint) {
    // Irregular blocks throughout the map
    final blocks = [
      Rect.fromLTWH(w * 0.02, h * 0.02, w * 0.12, h * 0.04),
      Rect.fromLTWH(w * 0.16, h * 0.01, w * 0.10, h * 0.05),
      Rect.fromLTWH(w * 0.30, h * 0.02, w * 0.15, h * 0.03),
      Rect.fromLTWH(w * 0.50, h * 0.01, w * 0.08, h * 0.04),
      Rect.fromLTWH(w * 0.70, h * 0.02, w * 0.12, h * 0.05),
      Rect.fromLTWH(w * 0.85, h * 0.01, w * 0.13, h * 0.04),
      // Row 2
      Rect.fromLTWH(w * 0.03, h * 0.08, w * 0.18, h * 0.06),
      Rect.fromLTWH(w * 0.24, h * 0.07, w * 0.12, h * 0.05),
      Rect.fromLTWH(w * 0.40, h * 0.08, w * 0.14, h * 0.04),
      Rect.fromLTWH(w * 0.58, h * 0.07, w * 0.10, h * 0.06),
      Rect.fromLTWH(w * 0.72, h * 0.09, w * 0.11, h * 0.04),
      Rect.fromLTWH(w * 0.86, h * 0.07, w * 0.12, h * 0.05),
      // Row 3
      Rect.fromLTWH(w * 0.01, h * 0.16, w * 0.14, h * 0.05),
      Rect.fromLTWH(w * 0.18, h * 0.15, w * 0.16, h * 0.06),
      Rect.fromLTWH(w * 0.38, h * 0.14, w * 0.10, h * 0.05),
      Rect.fromLTWH(w * 0.52, h * 0.16, w * 0.13, h * 0.04),
      Rect.fromLTWH(w * 0.68, h * 0.15, w * 0.15, h * 0.06),
      Rect.fromLTWH(w * 0.86, h * 0.14, w * 0.12, h * 0.05),
      // Row 4
      Rect.fromLTWH(w * 0.02, h * 0.24, w * 0.11, h * 0.05),
      Rect.fromLTWH(w * 0.16, h * 0.23, w * 0.18, h * 0.06),
      Rect.fromLTWH(w * 0.37, h * 0.22, w * 0.12, h * 0.05),
      Rect.fromLTWH(w * 0.53, h * 0.24, w * 0.14, h * 0.04),
      Rect.fromLTWH(w * 0.70, h * 0.23, w * 0.10, h * 0.06),
      Rect.fromLTWH(w * 0.83, h * 0.22, w * 0.15, h * 0.05),
      // Row 5
      Rect.fromLTWH(w * 0.04, h * 0.32, w * 0.13, h * 0.04),
      Rect.fromLTWH(w * 0.20, h * 0.31, w * 0.15, h * 0.06),
      Rect.fromLTWH(w * 0.38, h * 0.30, w * 0.11, h * 0.05),
      Rect.fromLTWH(w * 0.52, h * 0.32, w * 0.16, h * 0.04),
      Rect.fromLTWH(w * 0.72, h * 0.31, w * 0.12, h * 0.05),
      Rect.fromLTWH(w * 0.87, h * 0.30, w * 0.11, h * 0.06),
      // Row 6-10 (continue pattern down the screen)
      Rect.fromLTWH(w * 0.01, h * 0.40, w * 0.16, h * 0.05),
      Rect.fromLTWH(w * 0.20, h * 0.39, w * 0.12, h * 0.06),
      Rect.fromLTWH(w * 0.35, h * 0.40, w * 0.14, h * 0.04),
      Rect.fromLTWH(w * 0.53, h * 0.39, w * 0.11, h * 0.06),
      Rect.fromLTWH(w * 0.68, h * 0.41, w * 0.13, h * 0.04),
      Rect.fromLTWH(w * 0.84, h * 0.39, w * 0.14, h * 0.05),
      // Row 7
      Rect.fromLTWH(w * 0.03, h * 0.48, w * 0.14, h * 0.05),
      Rect.fromLTWH(w * 0.20, h * 0.47, w * 0.10, h * 0.04),
      Rect.fromLTWH(w * 0.34, h * 0.48, w * 0.16, h * 0.05),
      Rect.fromLTWH(w * 0.54, h * 0.47, w * 0.12, h * 0.06),
      Rect.fromLTWH(w * 0.70, h * 0.48, w * 0.14, h * 0.04),
      Rect.fromLTWH(w * 0.87, h * 0.47, w * 0.11, h * 0.06),
      // Row 8
      Rect.fromLTWH(w * 0.02, h * 0.56, w * 0.12, h * 0.05),
      Rect.fromLTWH(w * 0.17, h * 0.55, w * 0.15, h * 0.06),
      Rect.fromLTWH(w * 0.36, h * 0.56, w * 0.10, h * 0.04),
      Rect.fromLTWH(w * 0.50, h * 0.55, w * 0.14, h * 0.06),
      Rect.fromLTWH(w * 0.68, h * 0.57, w * 0.11, h * 0.04),
      Rect.fromLTWH(w * 0.82, h * 0.55, w * 0.16, h * 0.05),
      // Row 9
      Rect.fromLTWH(w * 0.04, h * 0.64, w * 0.15, h * 0.04),
      Rect.fromLTWH(w * 0.22, h * 0.63, w * 0.12, h * 0.06),
      Rect.fromLTWH(w * 0.38, h * 0.64, w * 0.14, h * 0.05),
      Rect.fromLTWH(w * 0.55, h * 0.63, w * 0.10, h * 0.06),
      Rect.fromLTWH(w * 0.69, h * 0.65, w * 0.13, h * 0.04),
      Rect.fromLTWH(w * 0.85, h * 0.63, w * 0.13, h * 0.06),
      // Row 10
      Rect.fromLTWH(w * 0.01, h * 0.72, w * 0.13, h * 0.05),
      Rect.fromLTWH(w * 0.17, h * 0.71, w * 0.16, h * 0.04),
      Rect.fromLTWH(w * 0.37, h * 0.72, w * 0.11, h * 0.06),
      Rect.fromLTWH(w * 0.52, h * 0.71, w * 0.14, h * 0.05),
      Rect.fromLTWH(w * 0.70, h * 0.73, w * 0.12, h * 0.04),
      Rect.fromLTWH(w * 0.85, h * 0.71, w * 0.13, h * 0.06),
      // Row 11
      Rect.fromLTWH(w * 0.03, h * 0.80, w * 0.14, h * 0.04),
      Rect.fromLTWH(w * 0.20, h * 0.79, w * 0.12, h * 0.06),
      Rect.fromLTWH(w * 0.35, h * 0.80, w * 0.15, h * 0.05),
      Rect.fromLTWH(w * 0.54, h * 0.79, w * 0.11, h * 0.06),
      Rect.fromLTWH(w * 0.69, h * 0.81, w * 0.14, h * 0.04),
      Rect.fromLTWH(w * 0.86, h * 0.79, w * 0.12, h * 0.05),
      // Row 12
      Rect.fromLTWH(w * 0.02, h * 0.88, w * 0.16, h * 0.05),
      Rect.fromLTWH(w * 0.21, h * 0.87, w * 0.13, h * 0.06),
      Rect.fromLTWH(w * 0.38, h * 0.88, w * 0.10, h * 0.04),
      Rect.fromLTWH(w * 0.52, h * 0.87, w * 0.15, h * 0.06),
      Rect.fromLTWH(w * 0.71, h * 0.89, w * 0.11, h * 0.04),
      Rect.fromLTWH(w * 0.85, h * 0.87, w * 0.13, h * 0.06),
      // Row 13
      Rect.fromLTWH(w * 0.01, h * 0.95, w * 0.14, h * 0.04),
      Rect.fromLTWH(w * 0.18, h * 0.94, w * 0.15, h * 0.05),
      Rect.fromLTWH(w * 0.36, h * 0.95, w * 0.12, h * 0.04),
      Rect.fromLTWH(w * 0.52, h * 0.94, w * 0.14, h * 0.05),
      Rect.fromLTWH(w * 0.70, h * 0.95, w * 0.13, h * 0.04),
      Rect.fromLTWH(w * 0.86, h * 0.94, w * 0.12, h * 0.05),
    ];

    for (final rect in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  void _drawWaterBodies(Canvas canvas, double w, double h) {
    final waterPaint = Paint()
      ..color = const Color(0xFF1A3545)
      ..style = PaintingStyle.fill;

    final waterEdgePaint = Paint()
      ..color = const Color(0xFF1E4055)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Main river (winding through left-center)
    final river1 = Path();
    river1.moveTo(w * 0.22, 0);
    river1.cubicTo(w * 0.20, h * 0.05, w * 0.15, h * 0.08, w * 0.12, h * 0.12);
    river1.cubicTo(w * 0.08, h * 0.18, w * 0.10, h * 0.22, w * 0.14, h * 0.28);
    river1.cubicTo(w * 0.18, h * 0.33, w * 0.12, h * 0.38, w * 0.08, h * 0.42);
    river1.cubicTo(w * 0.04, h * 0.46, w * 0.06, h * 0.52, w * 0.10, h * 0.56);
    river1.cubicTo(w * 0.14, h * 0.60, w * 0.10, h * 0.65, w * 0.06, h * 0.70);
    river1.cubicTo(w * 0.02, h * 0.75, w * 0.05, h * 0.80, w * 0.10, h * 0.85);
    river1.cubicTo(w * 0.15, h * 0.90, w * 0.12, h * 0.95, w * 0.14, h);
    // Return path (river width)
    river1.lineTo(w * 0.18, h);
    river1.cubicTo(w * 0.16, h * 0.95, w * 0.19, h * 0.90, w * 0.14, h * 0.85);
    river1.cubicTo(w * 0.09, h * 0.80, w * 0.06, h * 0.75, w * 0.10, h * 0.70);
    river1.cubicTo(w * 0.14, h * 0.65, w * 0.18, h * 0.60, w * 0.14, h * 0.56);
    river1.cubicTo(w * 0.10, h * 0.52, w * 0.08, h * 0.46, w * 0.12, h * 0.42);
    river1.cubicTo(w * 0.16, h * 0.38, w * 0.22, h * 0.33, w * 0.18, h * 0.28);
    river1.cubicTo(w * 0.14, h * 0.22, w * 0.12, h * 0.18, w * 0.16, h * 0.12);
    river1.cubicTo(w * 0.19, h * 0.08, w * 0.24, h * 0.05, w * 0.26, 0);
    river1.close();
    canvas.drawPath(river1, waterPaint);
    canvas.drawPath(river1, waterEdgePaint);

    // Secondary river / canal (right side)
    final river2 = Path();
    river2.moveTo(w * 0.75, 0);
    river2.cubicTo(w * 0.72, h * 0.06, w * 0.78, h * 0.12, w * 0.74, h * 0.18);
    river2.cubicTo(w * 0.70, h * 0.24, w * 0.76, h * 0.30, w * 0.72, h * 0.36);
    river2.cubicTo(w * 0.68, h * 0.42, w * 0.74, h * 0.48, w * 0.70, h * 0.54);
    river2.cubicTo(w * 0.66, h * 0.60, w * 0.72, h * 0.66, w * 0.68, h * 0.72);
    river2.cubicTo(w * 0.64, h * 0.78, w * 0.70, h * 0.84, w * 0.66, h * 0.90);
    river2.cubicTo(w * 0.62, h * 0.95, w * 0.65, h * 0.98, w * 0.63, h);
    river2.lineTo(w * 0.67, h);
    river2.cubicTo(w * 0.69, h * 0.98, w * 0.66, h * 0.95, w * 0.70, h * 0.90);
    river2.cubicTo(w * 0.74, h * 0.84, w * 0.68, h * 0.78, w * 0.72, h * 0.72);
    river2.cubicTo(w * 0.76, h * 0.66, w * 0.70, h * 0.60, w * 0.74, h * 0.54);
    river2.cubicTo(w * 0.78, h * 0.48, w * 0.72, h * 0.42, w * 0.76, h * 0.36);
    river2.cubicTo(w * 0.80, h * 0.30, w * 0.74, h * 0.24, w * 0.78, h * 0.18);
    river2.cubicTo(w * 0.82, h * 0.12, w * 0.76, h * 0.06, w * 0.79, 0);
    river2.close();
    canvas.drawPath(river2, waterPaint);
    canvas.drawPath(river2, waterEdgePaint);

    // Small canal connecting rivers
    final canal = Path();
    canal.moveTo(w * 0.18, h * 0.28);
    canal.cubicTo(w * 0.30, h * 0.26, w * 0.50, h * 0.30, w * 0.72, h * 0.36);
    canal.lineTo(w * 0.72, h * 0.38);
    canal.cubicTo(w * 0.50, h * 0.32, w * 0.30, h * 0.28, w * 0.18, h * 0.30);
    canal.close();
    canvas.drawPath(canal, waterPaint);

    // Another canal lower
    final canal2 = Path();
    canal2.moveTo(w * 0.14, h * 0.56);
    canal2.cubicTo(w * 0.25, h * 0.58, w * 0.45, h * 0.55, w * 0.70, h * 0.54);
    canal2.lineTo(w * 0.70, h * 0.56);
    canal2.cubicTo(w * 0.45, h * 0.57, w * 0.25, h * 0.60, w * 0.14, h * 0.58);
    canal2.close();
    canvas.drawPath(canal2, waterPaint);
  }

  void _drawParks(Canvas canvas, double w, double h) {
    final parkPaint = Paint()
      ..color = const Color(0xFF1E3528)
      ..style = PaintingStyle.fill;

    final parkOutline = Paint()
      ..color = const Color(0xFF244030)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final parks = [
      // Various parks scattered around
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.30, h * 0.05, w * 0.06, h * 0.025),
          const Radius.circular(3)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.55, h * 0.10, w * 0.04, h * 0.02),
          const Radius.circular(3)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.42, h * 0.18, w * 0.08, h * 0.03),
          const Radius.circular(4)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.85, h * 0.22, w * 0.05, h * 0.025),
          const Radius.circular(3)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.05, h * 0.35, w * 0.06, h * 0.03),
          const Radius.circular(4)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.48, h * 0.42, w * 0.07, h * 0.025),
          const Radius.circular(3)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.30, h * 0.50, w * 0.05, h * 0.02),
          const Radius.circular(3)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.82, h * 0.48, w * 0.06, h * 0.03),
          const Radius.circular(4)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.20, h * 0.62, w * 0.04, h * 0.025),
          const Radius.circular(3)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.60, h * 0.68, w * 0.07, h * 0.02),
          const Radius.circular(3)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.40, h * 0.76, w * 0.06, h * 0.03),
          const Radius.circular(4)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.15, h * 0.85, w * 0.05, h * 0.02),
          const Radius.circular(3)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.78, h * 0.82, w * 0.08, h * 0.025),
          const Radius.circular(4)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.55, h * 0.92, w * 0.05, h * 0.02),
          const Radius.circular(3)),
      // Larger park
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.35, h * 0.35, w * 0.10, h * 0.04),
          const Radius.circular(6)),
    ];

    for (final rrect in parks) {
      canvas.drawRRect(rrect, parkPaint);
      canvas.drawRRect(rrect, parkOutline);
    }
  }

  void _drawMinorStreets(
      Canvas canvas, double w, double h, Paint paint) {
    // Dense horizontal minor streets
    final hSpacings = [18.0, 22.0, 28.0, 15.0, 25.0, 20.0, 30.0, 17.0, 24.0];
    double y = 0;
    int idx = 0;
    while (y < h) {
      canvas.drawLine(Offset(0, y), Offset(w, y), paint);
      y += hSpacings[idx % hSpacings.length];
      idx++;
    }

    // Dense vertical minor streets
    final vSpacings = [20.0, 25.0, 18.0, 30.0, 22.0, 16.0, 28.0, 24.0];
    double x = 0;
    idx = 0;
    while (x < w) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
      x += vSpacings[idx % vSpacings.length];
      idx++;
    }
  }

  void _drawMediumStreets(
      Canvas canvas, double w, double h, Paint paint) {
    // Horizontal medium roads (irregular spacing)
    final hPositions = [
      h * 0.06, h * 0.13, h * 0.21, h * 0.30, h * 0.38,
      h * 0.46, h * 0.53, h * 0.62, h * 0.70, h * 0.78,
      h * 0.86, h * 0.93,
    ];
    for (final py in hPositions) {
      canvas.drawLine(Offset(0, py), Offset(w, py), paint);
    }

    // Vertical medium roads
    final vPositions = [
      w * 0.08, w * 0.17, w * 0.28, w * 0.38, w * 0.48,
      w * 0.58, w * 0.68, w * 0.80, w * 0.90,
    ];
    for (final px in vPositions) {
      canvas.drawLine(Offset(px, 0), Offset(px, h), paint);
    }
  }

  void _drawMajorRoads(
      Canvas canvas, double w, double h, Paint paint) {
    // Major horizontal arterials
    canvas.drawLine(Offset(0, h * 0.10), Offset(w, h * 0.10), paint);
    canvas.drawLine(Offset(0, h * 0.25), Offset(w, h * 0.25), paint);
    canvas.drawLine(Offset(0, h * 0.42), Offset(w, h * 0.42), paint);
    canvas.drawLine(Offset(0, h * 0.58), Offset(w, h * 0.58), paint);
    canvas.drawLine(Offset(0, h * 0.75), Offset(w, h * 0.75), paint);
    canvas.drawLine(Offset(0, h * 0.90), Offset(w, h * 0.90), paint);

    // Major vertical arterials
    canvas.drawLine(Offset(w * 0.15, 0), Offset(w * 0.15, h), paint);
    canvas.drawLine(Offset(w * 0.35, 0), Offset(w * 0.35, h), paint);
    canvas.drawLine(Offset(w * 0.55, 0), Offset(w * 0.55, h), paint);
    canvas.drawLine(Offset(w * 0.85, 0), Offset(w * 0.85, h), paint);
  }

  void _drawHighways(Canvas canvas, double w, double h, Paint paint) {
    // Curved highway 1 (top-left to bottom-right)
    final hw1 = Path();
    hw1.moveTo(0, h * 0.15);
    hw1.cubicTo(w * 0.15, h * 0.18, w * 0.30, h * 0.22, w * 0.45, h * 0.20);
    hw1.cubicTo(w * 0.60, h * 0.18, w * 0.75, h * 0.15, w, h * 0.12);
    canvas.drawPath(hw1, paint);

    // Curved highway 2 (across middle)
    final hw2 = Path();
    hw2.moveTo(0, h * 0.50);
    hw2.cubicTo(w * 0.20, h * 0.48, w * 0.40, h * 0.52, w * 0.60, h * 0.50);
    hw2.cubicTo(w * 0.80, h * 0.48, w * 0.90, h * 0.46, w, h * 0.48);
    canvas.drawPath(hw2, paint);

    // Curved highway 3 (lower)
    final hw3 = Path();
    hw3.moveTo(0, h * 0.82);
    hw3.cubicTo(w * 0.25, h * 0.80, w * 0.50, h * 0.85, w * 0.75, h * 0.83);
    hw3.cubicTo(w * 0.90, h * 0.82, w * 0.95, h * 0.80, w, h * 0.78);
    canvas.drawPath(hw3, paint);

    // Vertical highway
    final hw4 = Path();
    hw4.moveTo(w * 0.45, 0);
    hw4.cubicTo(w * 0.43, h * 0.20, w * 0.47, h * 0.40, w * 0.44, h * 0.60);
    hw4.cubicTo(w * 0.41, h * 0.80, w * 0.46, h * 0.90, w * 0.43, h);
    canvas.drawPath(hw4, paint);
  }

  void _drawDiagonalRoads(Canvas canvas, double w, double h,
      Paint medPaint, Paint majorPaint) {
    // Diagonal roads for realism
    final diag1 = Path();
    diag1.moveTo(0, h * 0.05);
    diag1.lineTo(w * 0.35, h * 0.25);
    canvas.drawPath(diag1, medPaint);

    final diag2 = Path();
    diag2.moveTo(w * 0.60, 0);
    diag2.cubicTo(w * 0.55, h * 0.10, w * 0.50, h * 0.15, w * 0.40, h * 0.30);
    canvas.drawPath(diag2, medPaint);

    final diag3 = Path();
    diag3.moveTo(w, h * 0.30);
    diag3.cubicTo(w * 0.85, h * 0.35, w * 0.75, h * 0.40, w * 0.60, h * 0.50);
    canvas.drawPath(diag3, majorPaint);

    final diag4 = Path();
    diag4.moveTo(0, h * 0.65);
    diag4.cubicTo(w * 0.15, h * 0.68, w * 0.30, h * 0.72, w * 0.50, h * 0.80);
    canvas.drawPath(diag4, medPaint);

    final diag5 = Path();
    diag5.moveTo(w * 0.80, h * 0.60);
    diag5.cubicTo(w * 0.85, h * 0.70, w * 0.90, h * 0.80, w, h * 0.95);
    canvas.drawPath(diag5, medPaint);

    // More curved connectors
    final diag6 = Path();
    diag6.moveTo(w * 0.25, h * 0.40);
    diag6.cubicTo(w * 0.30, h * 0.45, w * 0.40, h * 0.48, w * 0.55, h * 0.50);
    canvas.drawPath(diag6, medPaint);

    final diag7 = Path();
    diag7.moveTo(w * 0.10, h * 0.70);
    diag7.lineTo(w * 0.45, h * 0.60);
    canvas.drawPath(diag7, majorPaint);

    final diag8 = Path();
    diag8.moveTo(w * 0.50, h * 0.70);
    diag8.cubicTo(w * 0.60, h * 0.75, w * 0.75, h * 0.78, w * 0.90, h * 0.72);
    canvas.drawPath(diag8, medPaint);
  }

  void _drawRoundabouts(Canvas canvas, double w, double h) {
    final roundaboutPaint = Paint()
      ..color = const Color(0xFF3A4F62)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final centerPaint = Paint()
      ..color = const Color(0xFF1E3228)
      ..style = PaintingStyle.fill;

    final positions = [
      Offset(w * 0.35, h * 0.10),
      Offset(w * 0.55, h * 0.25),
      Offset(w * 0.15, h * 0.42),
      Offset(w * 0.85, h * 0.58),
      Offset(w * 0.45, h * 0.75),
      Offset(w * 0.25, h * 0.90),
    ];

    for (final pos in positions) {
      canvas.drawCircle(pos, 8, roundaboutPaint);
      canvas.drawCircle(pos, 3, centerPaint);
    }
  }

  void _drawBuildingDetails(Canvas canvas, double w, double h) {
    final bldgPaint = Paint()
      ..color = const Color(0xFF262F3A)
      ..style = PaintingStyle.fill;

    final bldgOutline = Paint()
      ..color = const Color(0xFF2A3848)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Scatter tiny rectangles to represent buildings
    final rng = [
      Rect.fromLTWH(w * 0.04, h * 0.03, 6, 5),
      Rect.fromLTWH(w * 0.06, h * 0.03, 4, 6),
      Rect.fromLTWH(w * 0.32, h * 0.06, 5, 4),
      Rect.fromLTWH(w * 0.34, h * 0.06, 3, 5),
      Rect.fromLTWH(w * 0.56, h * 0.11, 6, 5),
      Rect.fromLTWH(w * 0.59, h * 0.11, 4, 4),
      Rect.fromLTWH(w * 0.87, h * 0.23, 5, 6),
      Rect.fromLTWH(w * 0.90, h * 0.23, 4, 4),
      Rect.fromLTWH(w * 0.44, h * 0.19, 5, 5),
      Rect.fromLTWH(w * 0.47, h * 0.19, 3, 6),
      Rect.fromLTWH(w * 0.07, h * 0.36, 6, 4),
      Rect.fromLTWH(w * 0.10, h * 0.36, 4, 5),
      Rect.fromLTWH(w * 0.50, h * 0.43, 5, 5),
      Rect.fromLTWH(w * 0.53, h * 0.43, 3, 4),
      Rect.fromLTWH(w * 0.84, h * 0.49, 6, 5),
      Rect.fromLTWH(w * 0.87, h * 0.49, 4, 6),
      Rect.fromLTWH(w * 0.22, h * 0.63, 5, 4),
      Rect.fromLTWH(w * 0.25, h * 0.63, 3, 5),
      Rect.fromLTWH(w * 0.62, h * 0.69, 6, 5),
      Rect.fromLTWH(w * 0.65, h * 0.69, 4, 4),
      Rect.fromLTWH(w * 0.42, h * 0.77, 5, 6),
      Rect.fromLTWH(w * 0.45, h * 0.77, 3, 4),
      Rect.fromLTWH(w * 0.17, h * 0.86, 6, 5),
      Rect.fromLTWH(w * 0.20, h * 0.86, 4, 6),
      Rect.fromLTWH(w * 0.80, h * 0.83, 5, 4),
      Rect.fromLTWH(w * 0.83, h * 0.83, 3, 5),
      Rect.fromLTWH(w * 0.57, h * 0.93, 6, 5),
      Rect.fromLTWH(w * 0.60, h * 0.93, 4, 4),
    ];

    for (final rect in rng) {
      canvas.drawRect(rect, bldgPaint);
      canvas.drawRect(rect, bldgOutline);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

