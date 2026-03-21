import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/ride_request_service.dart';
import '../services/ride_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_back_button.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// RideRequestsArgs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class RideRequestsArgs {
  final int rideDetailId;
  final double totalRideCost;
  final int? driverProfileId;

  const RideRequestsArgs({
    required this.rideDetailId,
    required this.totalRideCost,
    this.driverProfileId,
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Passenger request model (built from RideRequest)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _PassengerRequest {
  /// The ride request ID — used for accept/reject API calls
  final int rideRequestId;
  final int userId;
  final String pickupAddress;
  final String dropAddress;
  final double passengerCost;
  final double passengerDistance;
  final String passengerFirstName;
  final String passengerLastName;
  final String? passengerPhone;
  final String? passengerProfileImageUrl;
  final String? pickupTimeAway;
  final String? dropTimeAway;
  UserProfile? profile;
  bool isAccepting;
  bool isRejecting;

  _PassengerRequest({
    required this.rideRequestId,
    required this.userId,
    required this.pickupAddress,
    required this.dropAddress,
    required this.passengerCost,
    required this.passengerDistance,
    this.passengerFirstName = '',
    this.passengerLastName = '',
    this.passengerPhone,
    this.passengerProfileImageUrl,
    this.pickupTimeAway,
    this.dropTimeAway,
    this.profile,
    this.isAccepting = false,
    this.isRejecting = false,
  });

  String get fullName => '$passengerFirstName $passengerLastName'.trim();
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// RideRequestsScreen — Driver sees pending passenger requests
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class RideRequestsScreen extends StatefulWidget {
  const RideRequestsScreen({super.key});

  @override
  State<RideRequestsScreen> createState() => _RideRequestsScreenState();
}

class _RideRequestsScreenState extends State<RideRequestsScreen> {
  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _darkCard = Color(0xFF1A2332);
  static const Color _costBg = Color(0xFFFFFFF0);

  RideRequestsArgs? _args;
  List<_PassengerRequest> _requests = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  double _totalRideCost = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is RideRequestsArgs) {
        _args = args;
        _totalRideCost = args.totalRideCost;
        _loadRequests();
        // Auto-refresh every 10 seconds to pick up new requests
        _refreshTimer = Timer.periodic(
          const Duration(seconds: 10),
          (_) => _loadRequests(),
        );
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (_args == null) return;

    try {
      // Use the correct endpoint: GET /ride-requests/driver/{driverProfileId}/pending
      // RideRequestsArgs carries rideDetailId — we need driverProfileId from the screen
      // Fall back to getting pending requests for the ride detail via cost-split approach.
      // Since the screen doesn't have driverProfileId, we use the ride-detail-based approach:
      // we load cost split to get total cost, and use ride requests endpoint.
      // The screen uses rideDetailId so we call /ride-requests/driver/ if we had profile.
      // For now we derive driverProfileId from token or use rideDetailId directly.

      // Note: RideRequestsArgs only has rideDetailId. The correct endpoint needs
      // driverProfileId. We pass -1 as a sentinel and handle in getDriverPendingRequests.
      // However the most reliable path is to use the driverProfileId if args had it.
      // Since we only have rideDetailId, let's use the driver ride-requests endpoint
      // with driverProfileId = 0 to try, then fall back to cost split.

      // Try cost-split first to update total cost display
      try {
        final costSplit = await RideService.getCostSplit(_args!.rideDetailId);
        if (mounted) setState(() => _totalRideCost = costSplit.totalRideCost);
      } catch (_) {}

      // Use the driverProfileId from args if available, else don't call the pending API
      final driverProfileId = _args!.driverProfileId;
      if (driverProfileId == null) {
        if (mounted) setState(() { _isLoading = false; _error = null; _requests = []; });
        return;
      }

      final rideRequests = await RideRequestService.getDriverPendingRequests(driverProfileId);

      final requests = <_PassengerRequest>[];
      for (final rr in rideRequests) {
        // Only show requests for this specific ride
        if (rr.rideDetailId != _args!.rideDetailId) continue;
        final req = _PassengerRequest(
          rideRequestId: rr.id,
          userId: rr.userId,
          pickupAddress: rr.startCity ?? 'Pickup location',
          dropAddress: rr.endCity ?? 'Drop location',
          passengerCost: rr.estimatedCost ?? 0,
          passengerDistance: rr.passengerRideDistance,
          passengerFirstName: rr.passengerFirstName,
          passengerLastName: rr.passengerLastName,
          passengerPhone: rr.passengerPhone,
          passengerProfileImageUrl: rr.passengerProfileImageUrl,
        );
        requests.add(req);
      }

      // Optionally load passenger profiles for richer display
      for (final req in requests) {
        try {
          final profile = await UserService.getUserProfileByUserId(req.userId.toString());
          req.profile = profile;
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }


  Future<void> _acceptRequest(_PassengerRequest req) async {
    setState(() => req.isAccepting = true);
    try {
      final updated = await RideRequestService.acceptRequest(req.rideRequestId);
      if (!mounted) return;

      final costText = updated.estimatedCost != null
          ? ' Cost: LKR ${updated.estimatedCost!.toStringAsFixed(2)}'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${req.fullName.isNotEmpty ? req.fullName : 'Passenger'} accepted!$costText 🎉'),
          backgroundColor: _accent,
        ),
      );

      // Remove from list and refresh
      setState(() => _requests.remove(req));
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      setState(() => req.isAccepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _rejectRequest(_PassengerRequest req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request?'),
        content: Text(
            'Reject the ride request from ${req.fullName.isNotEmpty ? req.fullName : 'this passenger'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => req.isRejecting = true);
    try {
      await RideRequestService.rejectRequest(req.rideRequestId);
      if (!mounted) return;
      setState(() => _requests.remove(req));
    } catch (e) {
      if (!mounted) return;
      setState(() => req.isRejecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dark map-like background
          Positioned.fill(
            child: CustomPaint(painter: _DarkMapPainter()),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      const CustomBackButton(),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ride Requests',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Refresh button
                      GestureDetector(
                        onTap: _isLoading ? null : _loadRequests,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _navy.withOpacity(0.8),
                          ),
                          child: _isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh,
                                  color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // ── Total cost banner ──
                _buildTotalCostBanner(),
                const SizedBox(height: 8),
                // ── Requests list ──
                Expanded(
                  child: _isLoading && _requests.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: _accent))
                      : _error != null && _requests.isEmpty
                          ? _buildErrorState()
                          : _requests.isEmpty
                              ? _buildEmptyState()
                              : _buildRequestsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCostBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      decoration: BoxDecoration(
        color: _costBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            children: [
              const TextSpan(
                  text: 'LKR ',
                  style: TextStyle(color: _accent)),
              TextSpan(
                text: _totalRideCost.toStringAsFixed(2),
                style: const TextStyle(color: _navy),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRequests,
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'No pending requests',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting for passengers to join your ride.\nThis screen auto-refreshes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _requests.length,
      itemBuilder: (ctx, i) => _buildPassengerCard(_requests[i]),
    );
  }

  // ── Passenger request card (matches the design image) ─────────

  Widget _buildPassengerCard(_PassengerRequest req) {
    final profile = req.profile;
    final name = profile != null
        ? '${profile.firstName} ${profile.lastName}'.trim()
        : req.fullName.isNotEmpty
            ? req.fullName
            : 'Passenger #${req.userId}';
    final photoUrl = req.passengerProfileImageUrl ??
        profile?.profileImageUrl ??
        profile?.userVerificationImageUrl;
    const rating = 4.9; // placeholder — add real rating when available

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _darkCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _accent, width: 2),
                  ),
                  child: ClipOval(
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _accent.withOpacity(0.2),
                              child: const Icon(Icons.person,
                                  color: Colors.white54, size: 30),
                            ),
                          )
                        : Container(
                            color: _accent.withOpacity(0.2),
                            child: const Icon(Icons.person,
                                color: Colors.white54, size: 30),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                          const Icon(Icons.star,
                              color: Colors.amber, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Cost badge ──
          Padding(
            padding: const EdgeInsets.fromLTRB(84, 8, 16, 0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.15)),
              ),
              child: Text(
                '- ${req.passengerCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // ── Pickup ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLocationRow(
              label: 'Pickup',
              address: req.pickupAddress,
              subtitle: _buildDistanceSubtitle(
                  req.pickupTimeAway, req.passengerDistance),
              dotColor: Colors.white,
            ),
          ),
          // Vertical connector line
          Padding(
            padding: const EdgeInsets.only(left: 27),
            child: Container(
              width: 2,
              height: 16,
              color: _accent.withOpacity(0.4),
            ),
          ),
          // ── Drop Off ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLocationRow(
              label: 'Drop Off',
              address: req.dropAddress,
              subtitle: _buildDistanceSubtitle(
                  req.dropTimeAway, req.passengerDistance),
              dotColor: _accent,
            ),
          ),
          const SizedBox(height: 18),
          // ── Accept / Reject buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Row(
              children: [
                // Accept button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: req.isAccepting || req.isRejecting
                          ? null
                          : () => _acceptRequest(req),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        disabledBackgroundColor:
                            _accent.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: req.isAccepting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Text(
                              'Accept',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Reject button
                SizedBox(
                  width: 50,
                  height: 50,
                  child: IconButton(
                    onPressed: req.isAccepting || req.isRejecting
                        ? null
                        : () => _rejectRequest(req),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: req.isRejecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red),
                          )
                        : const Icon(Icons.close,
                            color: Colors.red, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required String label,
    required String address,
    required String subtitle,
    required Color dotColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              border: Border.all(
                  color: dotColor == Colors.white
                      ? Colors.white
                      : _accent,
                  width: 2),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              if (subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '( $subtitle )',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildDistanceSubtitle(String? timeAway, double distance) {
    final parts = <String>[];
    if (timeAway != null && timeAway.isNotEmpty) parts.add(timeAway);
    if (distance > 0) parts.add('${distance.toStringAsFixed(2)} km');
    return parts.join(' ');
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Dark map painter — background
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _DarkMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = const Color(0xFF1A1E26);
    canvas.drawRect(Offset.zero & size, base);

    final road = Paint()
      ..color = const Color(0xFF2A2E38)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final water = Paint()
      ..color = const Color(0xFF0C2A36)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final rng = math.Random(42);
    for (var i = 0; i < 24; i++) {
      final y = (size.height / 24) * i + rng.nextDouble() * 12;
      canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y + rng.nextDouble() * 20 - 10),
          road);
    }
    for (var i = 0; i < 14; i++) {
      final x = (size.width / 14) * i + rng.nextDouble() * 16;
      canvas.drawLine(
          Offset(x, 0),
          Offset(x + rng.nextDouble() * 24 - 12, size.height),
          road);
    }
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.15, 0)
        ..quadraticBezierTo(size.width * 0.25, size.height * 0.4,
            size.width * 0.1, size.height),
      water,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.8, 0)
        ..quadraticBezierTo(size.width * 0.7, size.height * 0.5,
            size.width * 0.85, size.height),
      water,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

