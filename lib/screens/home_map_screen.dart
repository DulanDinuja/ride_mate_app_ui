import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  bool _showProfileCard = true;

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

          // Complete Profile Card
          if (_showProfileCard) _buildCompleteProfileCard(),
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

  Widget _buildCompleteProfileCard() {
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
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => setState(() => _showProfileCard = false),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Title
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                const Text(
                  "You're Almost Done! Complete Your Profile To Unlock All Features.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),

                // Progress bar + percentage
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0.75,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade800,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF03AF74),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '75%',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Complete Now button
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8 * 0.6,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to Profile Completion Screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03AF74),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
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

