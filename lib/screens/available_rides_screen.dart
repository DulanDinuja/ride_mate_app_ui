import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/routes/app_routes.dart';
import '../models/available_ride.dart';
import '../models/passenger_estimated_cost_response.dart';
import '../models/ride_request.dart';
import '../models/user_profile.dart';
import '../services/ride_request_service.dart';
import '../services/token_service.dart';
import '../widgets/custom_back_button.dart';

/// Screen that shows all ML-ranked available rides heading in the passenger's direction.
/// The passenger can browse rides, see estimated cost, and request to join one.
class AvailableRidesScreen extends StatefulWidget {
  final String pickupAddress;
  final String dropAddress;
  final double distanceKm;
  final LatLng pickupLatLng;
  final LatLng dropLatLng;
  final UserProfile? userProfile;

  const AvailableRidesScreen({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    required this.distanceKm,
    required this.pickupLatLng,
    required this.dropLatLng,
    this.userProfile,
  });

  @override
  State<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends State<AvailableRidesScreen> {
  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _cream = Color(0xFFFFFFF0);

  List<AvailableRide> _rides = [];
  bool _isLoading = true;
  String? _error;
  int? _requestingRideId;
  int? _estimatingRideId;

  @override
  void initState() {
    super.initState();
    _loadAvailableRides();
  }

  Future<void> _loadAvailableRides() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rides = await RideRequestService.getAvailableRides(
        startLat: widget.pickupLatLng.latitude,
        startLng: widget.pickupLatLng.longitude,
        endLat: widget.dropLatLng.latitude,
        endLng: widget.dropLatLng.longitude,
        passengerRideDistance: widget.distanceKm,
        radius: 15,
      );
      if (mounted) {
        setState(() {
          _rides = rides;
          _isLoading = false;
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

  Future<void> _showEstimate(AvailableRide ride) async {
    setState(() => _estimatingRideId = ride.rideDetailId);
    try {
      final estimate = await RideRequestService.estimateCost(
        rideDetailId: ride.rideDetailId,
        passengerRideDistance: widget.distanceKm,
      );
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _EstimateCostSheet(
          estimate: estimate,
          ride: ride,
          onConfirm: () {
            Navigator.pop(context);
            _requestToJoin(ride);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _estimatingRideId = null);
    }
  }

  Future<void> _requestToJoin(AvailableRide ride) async {
    int? userId = widget.userProfile?.userId;
    if (userId == null) {
      // Try to get userId from token
      final tokenUserId = await TokenService.getUserId();
      if (tokenUserId == null) {
        _showSnackBar('User not logged in', isError: true);
        return;
      }
      userId = int.tryParse(tokenUserId.toString());
      if (userId == null) {
        _showSnackBar('Invalid user session', isError: true);
        return;
      }
    }

    setState(() => _requestingRideId = ride.rideDetailId);

    try {
      final request = await RideRequestService.createRideRequest(
        rideDetailId: ride.rideDetailId,
        userId: userId!,
        passengerStartLat: widget.pickupLatLng.latitude,
        passengerStartLng: widget.pickupLatLng.longitude,
        passengerEndLat: widget.dropLatLng.latitude,
        passengerEndLng: widget.dropLatLng.longitude,
        passengerRideDistance: widget.distanceKm,
        startCity: widget.pickupAddress,
        endCity: widget.dropAddress,
      );

      if (!mounted) return;

      _showSnackBar('Request sent! Waiting for driver to accept.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _RideRequestStatusView(
            rideRequest: request,
            userId: userId!,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _requestingRideId = null);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        title: const Text('Available Rides'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableRides,
          ),
        ],
      ),
      body: Column(
        children: [
          // Route summary
          _buildRouteSummary(),
          // Rides list
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildRouteSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _routeRow(
              Icons.radio_button_checked, _accent, 'FROM', widget.pickupAddress),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Container(
                width: 2, height: 16, color: _accent.withOpacity(0.2)),
          ),
          _routeRow(
              Icons.location_on, Colors.red.shade400, 'TO', widget.dropAddress),
          const SizedBox(height: 8),
          Row(
            children: [
              _infoChip(Icons.straighten,
                  '${widget.distanceKm.toStringAsFixed(1)} km'),
              const SizedBox(width: 8),
              _infoChip(Icons.search, '${_rides.length} ride${_rides.length != 1 ? 's' : ''} found'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAvailableRides,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_rides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_car_outlined,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No rides available\nheading your way right now',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16, color: Colors.grey.shade500, height: 1.4),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _loadAvailableRides,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _loadAvailableRides,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _rides.length,
        itemBuilder: (context, index) => _buildRideCard(_rides[index], index),
      ),
    );
  }

  Widget _buildRideCard(AvailableRide ride, int index) {
    final isRequesting = _requestingRideId == ride.rideDetailId;
    final isEstimating = _estimatingRideId == ride.rideDetailId;
    final seatsLeft = ride.seatsRemaining;
    final estimatedCost =
        ride.estimatedCostPerPassenger ?? ride.totalRideCost;
    final mlRank = ride.mlRank;
    final mlProb = ride.mlAcceptanceProbability;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ML rank badge + driver info
            Row(
              children: [
                if (mlRank != null)
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: mlRank == 1
                          ? const Color(0xFFFFD700)
                          : mlRank == 2
                              ? Colors.grey.shade300
                              : const Color(0xFFCD7F32).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$mlRank',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: mlRank == 1
                            ? Colors.orange.shade800
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _accent.withOpacity(0.1),
                  child: ride.driverProfileImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            ride.driverProfileImageUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, color: _accent),
                          ),
                        )
                      : const Icon(Icons.person, color: _accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.driverFullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            ride.driverRating.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${ride.totalRidesAsDriver} rides',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                          if (mlProb != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${(mlProb * 100).toStringAsFixed(0)}% match',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: _accent,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Seats badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: seatsLeft > 0
                        ? _accent.withOpacity(0.1)
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_seat,
                          size: 14,
                          color: seatsLeft > 0
                              ? _accent
                              : Colors.red.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '$seatsLeft left',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: seatsLeft > 0
                              ? _accent
                              : Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Route
            _routeRow(Icons.radio_button_checked, _accent, 'FROM',
                ride.startCity ?? 'Pickup'),
            const SizedBox(height: 6),
            _routeRow(Icons.location_on, Colors.red.shade400, 'TO',
                ride.endCity ?? 'Drop'),

            const SizedBox(height: 12),

            // Cost row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR ESTIMATED COST',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.black38,
                            letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'LKR ${estimatedCost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _accent,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total ride',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                    ),
                    Text(
                      'LKR ${ride.totalRideCost.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),

            if (ride.vehicleDescription != 'Vehicle') ...[
              const SizedBox(height: 8),
              _infoChip(Icons.directions_car, ride.vehicleDescription),
            ],
            if (ride.vehiclePlateNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                ride.vehiclePlateNumber!,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500),
              ),
            ],

            const SizedBox(height: 16),

            // Estimate + Request buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: seatsLeft > 0 && !isEstimating && !isRequesting
                          ? () => _showEstimate(ride)
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _navy,
                        side: const BorderSide(color: _navy),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isEstimating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _navy))
                          : const Text('See Cost',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: seatsLeft > 0 &&
                              !isRequesting &&
                              !isEstimating
                          ? () => _requestToJoin(ride)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        disabledBackgroundColor: _accent.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isRequesting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              seatsLeft > 0 ? 'Request to Join' : 'No Seats',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeRow(
      IconData icon, Color iconColor, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black38,
                      letterSpacing: 1)),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _navy)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Estimate cost bottom sheet
// ═══════════════════════════════════════════════════════════════════

class _EstimateCostSheet extends StatelessWidget {
  final PassengerEstimatedCostResponse estimate;
  final AvailableRide ride;
  final VoidCallback onConfirm;

  const _EstimateCostSheet({
    required this.estimate,
    required this.ride,
    required this.onConfirm,
  });

  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFF0),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Estimated Cost',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: _navy),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'LKR ${estimate.estimatedCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _accent),
                ),
                const SizedBox(height: 4),
                Text(
                  '${estimate.sharePercentage.toStringAsFixed(0)}% share of the ride',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Details grid
          Row(
            children: [
              _detailTile('Distance',
                  '${estimate.passengerRideDistance.toStringAsFixed(1)} km'),
              const SizedBox(width: 10),
              _detailTile('Per km', 'LKR ${estimate.perKmRate.toStringAsFixed(0)}'),
              const SizedBox(width: 10),
              _detailTile('Passengers',
                  '${estimate.currentPassengerCount} + you'),
            ],
          ),
          if (estimate.pricingNote != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      estimate.pricingNote!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Request to Join',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _navy)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Ride request status view — polls for accept/reject, shows cost on accept
// ═══════════════════════════════════════════════════════════════════

class _RideRequestStatusView extends StatefulWidget {
  final RideRequest rideRequest;
  final int userId;

  const _RideRequestStatusView({
    required this.rideRequest,
    required this.userId,
  });

  @override
  State<_RideRequestStatusView> createState() =>
      _RideRequestStatusViewState();
}

class _RideRequestStatusViewState extends State<_RideRequestStatusView> {
  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _cream = Color(0xFFFFFFF0);

  late RideRequest _currentRequest;
  bool _isPolling = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.rideRequest;
    _startPolling();
  }

  @override
  void dispose() {
    _isPolling = false;
    super.dispose();
  }

  Future<void> _startPolling() async {
    while (_isPolling &&
        mounted &&
        (_currentRequest.isPending)) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted || !_isPolling) return;
      try {
        final requests =
            await RideRequestService.getPassengerRequests(widget.userId);
        final updated = requests.firstWhere(
          (r) => r.id == _currentRequest.id,
          orElse: () => _currentRequest,
        );
        if (mounted) setState(() => _currentRequest = updated);
      } catch (_) {
        // silently retry
      }
    }
  }

  Future<void> _cancelRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text(
            'Are you sure you want to cancel this ride request?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Yes', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      final updated =
          await RideRequestService.cancelRequest(_currentRequest.id);
      if (mounted) {
        setState(() {
          _currentRequest = updated;
          _isCancelling = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Ride Request Status'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusIcon(),
              const SizedBox(height: 24),
              Text(
                _statusTitle(),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _navy),
              ),
              const SizedBox(height: 12),
              Text(
                _statusMessage(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.4),
              ),
              const SizedBox(height: 32),

              if (_currentRequest.isPending) ...[
                const CircularProgressIndicator(color: _accent),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isCancelling ? null : _cancelRequest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isCancelling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red))
                        : const Text('Cancel Request',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],

              // Accepted — show estimated cost
              if (_currentRequest.isAccepted) ...[
                if (_currentRequest.estimatedCost != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'YOUR RIDE COST',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black45,
                              letterSpacing: 1),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'LKR ${_currentRequest.estimatedCost!.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: _accent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.costSplit,
                        (route) => route.settings.name == AppRoutes.userHomeMap ||
                            route.isFirst,
                        arguments: {
                          'rideDetailId': _currentRequest.rideDetailId,
                          'isDriver': false,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'View Ride Details',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],

              if (_currentRequest.isRejected ||
                  _currentRequest.isCancelled) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Browse Other Rides',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_currentRequest.isPending) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
            color: Colors.orange.shade50, shape: BoxShape.circle),
        child: Icon(Icons.hourglass_top,
            size: 40, color: Colors.orange.shade400),
      );
    } else if (_currentRequest.isAccepted) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
            color: _accent.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.check_circle, size: 40, color: _accent),
      );
    } else {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
            color: Colors.red.shade50, shape: BoxShape.circle),
        child: Icon(Icons.cancel, size: 40, color: Colors.red.shade400),
      );
    }
  }

  String _statusTitle() {
    if (_currentRequest.isPending) return 'Request Pending';
    if (_currentRequest.isAccepted) return 'Request Accepted! 🎉';
    if (_currentRequest.isCancelled) return 'Request Cancelled';
    return 'Request Declined';
  }

  String _statusMessage() {
    if (_currentRequest.isPending) {
      return 'Your request has been sent to the driver.\nPlease wait for them to respond.';
    }
    if (_currentRequest.isAccepted) {
      return 'The driver has accepted your request!\nYou have been added to the ride.';
    }
    if (_currentRequest.isCancelled) {
      return 'You have cancelled your request.\nYou can browse other rides.';
    }
    return 'Unfortunately the driver declined your request.\nYou can try requesting another ride.';
  }
}

