import 'package:flutter/material.dart';
import 'dart:math' as math;

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
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

  /// Top section: menu button only
  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
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

/// Custom painter for a dark city-style map background.
class _MapPatternPainter extends CustomPainter {
  static const Color _landBase = Color(0xFF2A2C34);
  static const Color _landBand = Color(0xFF30333C);
  static const Color _minorRoad = Color(0xFF5A5E67);
  static const Color _collectorRoad = Color(0xFF6F747D);
  static const Color _arterialRoad = Color(0xFF8C9098);
  static const Color _waterFill = Color(0xFF0E3F4A);
  static const Color _waterEdge = Color(0xFF165A69);
  static const Color _parkFill = Color(0xFF1A3A16);
  static const Color _parkEdge = Color(0xFF2E5A2A);

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    canvas.drawRect(area, Paint()..color = _landBase);

    _drawLandBands(canvas, size);
    _drawWater(canvas, size);
    _drawParks(canvas, size);
    _drawRoadHierarchy(canvas, size);
    _drawNeighborhoodStreets(canvas, size);
    _drawDetailAccents(canvas, size);
  }

  void _drawLandBands(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bandPaint = Paint()..color = _landBand.withOpacity(0.28);

    final bands = [
      Rect.fromLTWH(0, h * 0.08, w, h * 0.07),
      Rect.fromLTWH(0, h * 0.31, w, h * 0.06),
      Rect.fromLTWH(0, h * 0.55, w, h * 0.08),
      Rect.fromLTWH(0, h * 0.79, w, h * 0.06),
    ];

    for (final band in bands) {
      canvas.drawRect(band, bandPaint);
    }
  }

  void _drawWater(Canvas canvas, Size size) {
    final fill = Paint()..color = _waterFill.withOpacity(0.72);
    final edge = Paint()
      ..color = _waterEdge.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final mainRiver = _ribbonPath(
      size,
      const [
        Offset(-0.08, 0.12),
        Offset(0.14, 0.24),
        Offset(0.30, 0.32),
        Offset(0.54, 0.40),
        Offset(0.76, 0.53),
        Offset(1.05, 0.66),
      ],
      widthFactor: 0.032,
    );

    final southRiver = _ribbonPath(
      size,
      const [
        Offset(-0.10, 0.90),
        Offset(0.18, 0.84),
        Offset(0.38, 0.80),
        Offset(0.60, 0.87),
        Offset(0.86, 0.91),
        Offset(1.08, 0.95),
      ],
      widthFactor: 0.028,
    );

    final branch = _ribbonPath(
      size,
      const [
        Offset(0.74, -0.06),
        Offset(0.70, 0.16),
        Offset(0.76, 0.34),
        Offset(0.70, 0.48),
        Offset(0.76, 0.70),
        Offset(0.72, 1.05),
      ],
      widthFactor: 0.018,
    );

    final canal = _ribbonPath(
      size,
      const [
        Offset(0.08, 0.44),
        Offset(0.24, 0.47),
        Offset(0.42, 0.49),
        Offset(0.64, 0.46),
        Offset(0.82, 0.44),
      ],
      widthFactor: 0.011,
    );

    for (final water in [mainRiver, southRiver, branch, canal]) {
      canvas.drawPath(water, fill);
      canvas.drawPath(water, edge);
    }
  }

  void _drawParks(Canvas canvas, Size size) {
    final fill = Paint()..color = _parkFill.withOpacity(0.82);
    final edge = Paint()
      ..color = _parkEdge.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final parkShapes = [
      _blobPath(size, const [
        Offset(0.08, 0.18),
        Offset(0.13, 0.17),
        Offset(0.16, 0.20),
        Offset(0.14, 0.24),
        Offset(0.09, 0.23),
      ]),
      _blobPath(size, const [
        Offset(0.56, 0.34),
        Offset(0.63, 0.33),
        Offset(0.66, 0.38),
        Offset(0.61, 0.41),
        Offset(0.55, 0.39),
      ]),
      _blobPath(size, const [
        Offset(0.34, 0.58),
        Offset(0.42, 0.56),
        Offset(0.46, 0.61),
        Offset(0.41, 0.66),
        Offset(0.33, 0.64),
      ]),
      _blobPath(size, const [
        Offset(0.74, 0.72),
        Offset(0.83, 0.69),
        Offset(0.86, 0.75),
        Offset(0.81, 0.79),
        Offset(0.73, 0.78),
      ]),
      _blobPath(size, const [
        Offset(0.22, 0.86),
        Offset(0.30, 0.84),
        Offset(0.34, 0.89),
        Offset(0.29, 0.92),
        Offset(0.21, 0.91),
      ]),
    ];

    for (final park in parkShapes) {
      canvas.drawPath(park, fill);
      canvas.drawPath(park, edge);
    }
  }

  void _drawRoadHierarchy(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = _minorRoad.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final collector = Paint()
      ..color = _collectorRoad.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final arterial = Paint()
      ..color = _arterialRoad
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.1
      ..strokeCap = StrokeCap.round;

    final arterials = [
      _polyPath(size, const [Offset(-0.05, 0.20), Offset(1.06, 0.19)]),
      _polyPath(size, const [Offset(-0.04, 0.42), Offset(1.04, 0.42)]),
      _polyPath(size, const [Offset(-0.06, 0.63), Offset(1.02, 0.61)]),
      _polyPath(size, const [Offset(-0.05, 0.79), Offset(1.04, 0.83)]),
      _polyPath(size, const [Offset(0.19, -0.04), Offset(0.18, 1.06)]),
      _polyPath(size, const [Offset(0.52, -0.06), Offset(0.50, 1.04)]),
      _polyPath(size, const [Offset(0.82, -0.04), Offset(0.85, 1.06)]),
      _polyPath(size, const [
        Offset(-0.08, 0.30),
        Offset(0.18, 0.36),
        Offset(0.40, 0.41),
        Offset(0.62, 0.47),
        Offset(1.04, 0.52),
      ]),
      _polyPath(size, const [
        Offset(-0.07, 0.74),
        Offset(0.20, 0.69),
        Offset(0.44, 0.73),
        Offset(0.69, 0.78),
        Offset(1.04, 0.76),
      ]),
    ];

    final collectors = [
      for (final y in [0.10, 0.15, 0.27, 0.35, 0.50, 0.56, 0.70, 0.88])
        _polyPath(size, [Offset(-0.02, y), Offset(1.02, y)]),
      for (final x in [0.08, 0.28, 0.36, 0.62, 0.71, 0.92])
        _polyPath(size, [Offset(x, -0.02), Offset(x, 1.02)]),
      _polyPath(size, const [
        Offset(0.04, 0.05),
        Offset(0.22, 0.14),
        Offset(0.40, 0.22),
      ]),
      _polyPath(size, const [
        Offset(0.64, 0.28),
        Offset(0.78, 0.38),
        Offset(0.96, 0.47),
      ]),
      _polyPath(size, const [
        Offset(0.14, 0.88),
        Offset(0.36, 0.84),
        Offset(0.57, 0.85),
      ]),
    ];

    final minorDiagonals = [
      _polyPath(size, const [Offset(0.04, 0.58), Offset(0.26, 0.52)]),
      _polyPath(size, const [Offset(0.28, 0.48), Offset(0.56, 0.59)]),
      _polyPath(size, const [Offset(0.54, 0.67), Offset(0.90, 0.58)]),
      _polyPath(size, const [Offset(0.66, 0.88), Offset(0.95, 0.98)]),
    ];

    for (final path in minorDiagonals) {
      canvas.drawPath(path, minor);
    }
    for (final path in collectors) {
      canvas.drawPath(path, collector);
    }
    for (final path in arterials) {
      canvas.drawPath(path, arterial);
    }

    final ringPaint = Paint()
      ..color = _collectorRoad.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final node in [
      Offset(size.width * 0.26, size.height * 0.42),
      Offset(size.width * 0.52, size.height * 0.61),
      Offset(size.width * 0.82, size.height * 0.80),
    ]) {
      canvas.drawCircle(node, 7.5, ringPaint);
    }
  }

  void _drawNeighborhoodStreets(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _minorRoad.withOpacity(0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final w = size.width;
    final h = size.height;

    final horizontalSpacings = [20.0, 26.0, 18.0, 24.0, 22.0, 19.0];
    final verticalSpacings = [17.0, 23.0, 28.0, 21.0, 19.0, 25.0];

    double y = 6;
    int yi = 0;
    while (y < h) {
      canvas.drawLine(Offset(0, y), Offset(w, y), paint);
      y += horizontalSpacings[yi % horizontalSpacings.length];
      yi++;
    }

    double x = 4;
    int xi = 0;
    while (x < w) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
      x += verticalSpacings[xi % verticalSpacings.length];
      xi++;
    }
  }

  void _drawDetailAccents(Canvas canvas, Size size) {
    final buildingFill = Paint()..color = const Color(0xFF353844).withOpacity(0.75);
    final buildingStroke = Paint()
      ..color = const Color(0xFF444956).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final details = [
      const Offset(0.12, 0.14),
      const Offset(0.18, 0.29),
      const Offset(0.42, 0.26),
      const Offset(0.58, 0.47),
      const Offset(0.77, 0.36),
      const Offset(0.14, 0.67),
      const Offset(0.36, 0.73),
      const Offset(0.63, 0.74),
      const Offset(0.84, 0.90),
    ];

    for (final p in details) {
      final rect = Rect.fromLTWH(
        p.dx * size.width,
        p.dy * size.height,
        10,
        7,
      );
      canvas.drawRect(rect, buildingFill);
      canvas.drawRect(rect, buildingStroke);
    }
  }

  Path _polyPath(Size size, List<Offset> normalizedPoints) {
    final path = Path();
    if (normalizedPoints.isEmpty) return path;

    final first = normalizedPoints.first;
    path.moveTo(first.dx * size.width, first.dy * size.height);
    for (var i = 1; i < normalizedPoints.length; i++) {
      final point = normalizedPoints[i];
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    return path;
  }

  Path _blobPath(Size size, List<Offset> normalizedPoints) {
    final path = Path();
    if (normalizedPoints.length < 3) return path;

    final scaled = [
      for (final point in normalizedPoints)
        Offset(point.dx * size.width, point.dy * size.height),
    ];

    path.moveTo(scaled.first.dx, scaled.first.dy);
    for (var i = 0; i < scaled.length; i++) {
      final current = scaled[i];
      final next = scaled[(i + 1) % scaled.length];
      final mid = Offset((current.dx + next.dx) / 2, (current.dy + next.dy) / 2);
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }

  Path _ribbonPath(
    Size size,
    List<Offset> centerLine, {
    required double widthFactor,
  }) {
    final width = size.width * widthFactor;
    final points = [
      for (final point in centerLine)
        Offset(point.dx * size.width, point.dy * size.height),
    ];

    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final prev = points[i == 0 ? i : i - 1];
      final next = points[i == points.length - 1 ? i : i + 1];
      final dx = next.dx - prev.dx;
      final dy = next.dy - prev.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      final nx = len == 0 ? 0.0 : -dy / len;
      final ny = len == 0 ? 0.0 : dx / len;
      left.add(Offset(points[i].dx + nx * width, points[i].dy + ny * width));
      right.add(Offset(points[i].dx - nx * width, points[i].dy - ny * width));
    }

    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (var i = 1; i < left.length; i++) {
      final a = left[i - 1];
      final b = left[i];
      path.quadraticBezierTo(a.dx, a.dy, (a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    }
    for (var i = right.length - 1; i >= 1; i--) {
      final a = right[i];
      final b = right[i - 1];
      path.quadraticBezierTo(a.dx, a.dy, (a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

