import 'dart:async';

import 'package:flutter/material.dart';

import '../core/routes/app_routes.dart';
import '../models/cost_split_response.dart';
import '../services/ride_service.dart';
import '../services/ride_request_service.dart';
import '../utils/vehicle_capacity.dart';
import '../widgets/custom_back_button.dart';
import 'cost_split_screen.dart';
import 'driver_ride_requests_screen.dart';
import 'help_support_screen.dart';

/// The driver can view the full cost breakdown, and the screen auto-refreshes.
class ActiveRideScreen extends StatefulWidget {
  final int rideDetailId;
  final int? driverProfileId;
  final String pickupAddress;
  final String dropAddress;
  final double totalDistance;
  final double totalCost;
  /// Vehicle type name used to enforce maximum seat capacity.
  /// e.g. "BIKE", "CAR", "TUK_TUK". Defaults to null (uses 3-seat default).
  final String? vehicleTypeName;

  const ActiveRideScreen({
    super.key,
    required this.rideDetailId,
    this.driverProfileId,
    required this.pickupAddress,
    required this.dropAddress,
    required this.totalDistance,
    required this.totalCost,
    this.vehicleTypeName,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _cream = Color(0xFFFFFFF0);

  CostSplitResponse? _costSplit;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  int _pendingRequestCount = 0;
  bool _isEndingRide = false;

  @override
  void initState() {
    super.initState();
    _loadCostSplit();
    _loadPendingRequests();
    // Auto-refresh every 15 seconds to pick up new passengers
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        _loadCostSplit();
        _loadPendingRequests();
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCostSplit() async {
    try {
      final data = await RideService.getCostSplit(widget.rideDetailId);
      if (mounted) {
        setState(() {
          _costSplit = data;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _loadPendingRequests() async {
    if (widget.driverProfileId == null) return;
    try {
      final requests = await RideRequestService.getDriverPendingRequests(
          widget.driverProfileId!);
      if (mounted) {
        setState(() => _pendingRequestCount = requests.length);
      }
    } catch (_) {
      // silently ignore — badge simply won't update
    }
  }

  void _openRideRequests() {
    if (widget.driverProfileId == null) return;
    final maxSeats = VehicleCapacityUtils.maxSeats(widget.vehicleTypeName);
    final currentPassengers = _costSplit?.totalPassengers ?? 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverRideRequestsScreen(
          driverProfileId: widget.driverProfileId!,
          rideDetailId: widget.rideDetailId,
          maxSeats: maxSeats,
          currentPassengers: currentPassengers,
        ),
      ),
    ).then((_) {
      _loadPendingRequests();
      _loadCostSplit();
    });
  }

  Future<void> _endRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End This Ride?'),
        content: const Text(
          'This will mark the ride as COMPLETED.\nPassengers will see the final cost split.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Ride',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isEndingRide = true);
    try {
      await RideService.endRide(widget.rideDetailId);
      if (!mounted) return;
      // Show final cost split then pop back
      await _loadCostSplit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride ended successfully! 🎉'),
          backgroundColor: Color(0xFF03AF74),
        ),
      );
      // Navigate to cost split screen for final summary
      // Clear stale ride screens (RideStartScreen etc.) from the stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => CostSplitScreen(
            rideDetailId: widget.rideDetailId,
            initialData: _costSplit,
            isDriver: true,
          ),
        ),
        (route) =>
            route.settings.name == AppRoutes.userHomeMap ||
            route.settings.name == AppRoutes.driverHomeMap ||
            route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isEndingRide = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _openFullBreakdown() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CostSplitScreen(
          rideDetailId: widget.rideDetailId,
          initialData: _costSplit,
          isDriver: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(6),
          child: CustomBackButton(),
        ),
        title: const Text('Active Ride'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        actions: [
          // Emergency help icon in AppBar
          IconButton(
            icon: const Icon(Icons.health_and_safety_outlined,
                color: Color(0xFFEF9A9A)),
            tooltip: 'Emergency Help',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const HelpSupportScreen(isEmergencyMode: true),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCostSplit,
          ),
        ],
      ),
      body: _isLoading && _costSplit == null
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final maxSeats = VehicleCapacityUtils.maxSeats(widget.vehicleTypeName);
    final currentPassengers = _costSplit?.totalPassengers ?? 0;
    final isFull = currentPassengers >= maxSeats;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Route card ──
        _buildRouteCard(),
        const SizedBox(height: 16),

        // ── Seat capacity card ──
        _buildSeatCapacityCard(
          maxSeats: maxSeats,
          currentPassengers: currentPassengers,
          isFull: isFull,
        ),
        const SizedBox(height: 16),

        // ── Cost summary ──
        _buildCostSummary(),
        const SizedBox(height: 16),

        // ── Passengers ──
        _buildPassengersSection(),
        const SizedBox(height: 16),

        // ── View ride requests button (with pending count badge) ──
        if (widget.driverProfileId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                if (isFull)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_seat, color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vehicle is at full capacity ($currentPassengers/$maxSeats). '
                            'New ride requests cannot be accepted.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isFull ? null : _openRideRequests,
                    icon: Badge(
                      isLabelVisible: _pendingRequestCount > 0,
                      label: Text('$_pendingRequestCount'),
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.person_add_alt_1),
                    ),
                    label: Text(
                      isFull
                          ? 'Vehicle Full — No More Seats'
                          : _pendingRequestCount > 0
                              ? 'Ride Requests ($_pendingRequestCount pending)'
                              : 'Ride Requests',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFull ? Colors.grey.shade400 : _accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── View full breakdown button ──
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _costSplit != null ? _openFullBreakdown : null,
            icon: const Icon(Icons.analytics_outlined),
            label: const Text(
              'View Full Cost Breakdown',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── End ride button ──
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _isEndingRide ? null : _endRide,
            icon: _isEndingRide
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.red))
                : const Icon(Icons.stop_circle_outlined),
            label: Text(
              _isEndingRide ? 'Ending Ride...' : 'End Ride',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSeatCapacityCard({
    required int maxSeats,
    required int currentPassengers,
    required bool isFull,
  }) {
    final vehicleLabel = VehicleCapacityUtils.vehicleLabel(widget.vehicleTypeName);
    final emoji = VehicleCapacityUtils.vehicleEmoji(widget.vehicleTypeName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Seat Capacity  ·  $vehicleLabel',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFull
                      ? Colors.red.withOpacity(0.12)
                      : _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isFull ? 'FULL' : '$currentPassengers / $maxSeats',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isFull ? Colors.red.shade700 : _accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: maxSeats == 0 ? 0 : currentPassengers / maxSeats,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull ? Colors.red.shade500 : _accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Seat icons row
          Row(
            children: List.generate(maxSeats, (i) {
              final filled = i < currentPassengers;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  filled ? Icons.event_seat : Icons.event_seat_outlined,
                  size: 20,
                  color: filled
                      ? (isFull ? Colors.red.shade500 : _accent)
                      : Colors.grey.shade300,
                ),
              );
            }),
            // Add overflow label if maxSeats > 6
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const Icon(Icons.radio_button_checked,
                  color: _accent, size: 20),
              Container(
                  width: 2, height: 40, color: _accent.withOpacity(0.3)),
              Icon(Icons.location_on,
                  color: Colors.red.shade400, size: 20),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FROM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black38,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.pickupAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'TO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black38,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.dropAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary() {
    final data = _costSplit;
    final effectiveCost = data?.driverEffectiveCost ?? widget.totalCost;
    final totalCost = data?.totalRideCost ?? widget.totalCost;
    final passengers = data?.totalPassengers ?? 0;
    final saved = totalCost - effectiveCost;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF040F1B), Color(0xFF0A2540)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR COST',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'LKR ${effectiveCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (passengers > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'SAVED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white54,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'LKR ${saved.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _accent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMiniStat(
                  Icons.straighten, '${widget.totalDistance.toStringAsFixed(1)} km'),
              const SizedBox(width: 10),
              _buildMiniStat(
                  Icons.people, '$passengers passenger${passengers != 1 ? 's' : ''}'),
              const SizedBox(width: 10),
              _buildMiniStat(
                  Icons.receipt_long, 'Total: LKR ${totalCost.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: Colors.white54),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengersSection() {
    final passengers = _costSplit?.passengerCosts ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.people, size: 18, color: Colors.blue),
              ),
              const SizedBox(width: 10),
              Text(
                'Passengers (${passengers.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ],
          ),
          if (passengers.isEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(Icons.hourglass_empty,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'Waiting for passengers to join...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'People along your route will be able to request a ride.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            ...passengers.map((pax) => _buildPassengerTile(pax)),
        ],
      ),
    );
  }

  Widget _buildPassengerTile(PassengerCostDetail pax) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child:
                  const Icon(Icons.person, color: Colors.blue, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pax.startCity ?? 'Pickup'} → ${pax.endCity ?? 'Drop'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pax.passengerRideDistance.toStringAsFixed(1)} km • '
                    '${pax.segmentBreakdown.length} segment${pax.segmentBreakdown.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'LKR ${pax.totalPassengerCost.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

