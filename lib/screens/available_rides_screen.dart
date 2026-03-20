import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/available_ride.dart';
import '../models/ride_request.dart';
import '../models/user_profile.dart';
import '../services/ride_request_service.dart';
import '../widgets/custom_back_button.dart';

/// Screen that shows all available rides heading in the passenger's direction.
/// The passenger can browse rides and request to join one.
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
  int? _requestingRideId; // ride being requested

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
        endLat: widget.dropLatLng.latitude,
        endLng: widget.dropLatLng.longitude,
        radiusKm: 15,
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

  Future<void> _requestToJoin(AvailableRide ride) async {
    final userId = widget.userProfile?.userId;
    if (userId == null) {
      _showSnackBar('User not logged in', isError: true);
      return;
    }

    setState(() => _requestingRideId = ride.rideDetailId);

    try {
      final request = await RideRequestService.createRideRequest(
        rideDetailId: ride.rideDetailId,
        userId: userId,
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

      // Navigate to request status screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _RideRequestStatusView(
            rideRequest: request,
            userId: userId,
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
          _routeRow(Icons.radio_button_checked, _accent, 'FROM',
              widget.pickupAddress),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Container(width: 2, height: 16, color: _accent.withOpacity(0.2)),
          ),
          _routeRow(Icons.location_on, Colors.red.shade400, 'TO',
              widget.dropAddress),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.straighten, size: 14, color: _accent),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ),
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
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
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
        itemBuilder: (context, index) => _buildRideCard(_rides[index]),
      ),
    );
  }

  Widget _buildRideCard(AvailableRide ride) {
    final isRequesting = _requestingRideId == ride.rideDetailId;
    final seatsLeft = ride.seatsRemaining;

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
            // Driver info row
            Row(
              children: [
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
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${ride.totalRidesAsDriver} rides',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Seats badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          color:
                              seatsLeft > 0 ? _accent : Colors.red.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '$seatsLeft left',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              seatsLeft > 0 ? _accent : Colors.red.shade400,
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
                ride.startCity ?? 'Unknown'),
            const SizedBox(height: 6),
            _routeRow(Icons.location_on, Colors.red.shade400, 'TO',
                ride.endCity ?? 'Unknown'),

            const SizedBox(height: 12),

            // Vehicle & cost info
            Row(
              children: [
                _infoChip(Icons.directions_car, ride.vehicleDescription),
                const Spacer(),
                Text(
                  'LKR ${ride.totalRideCost.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
              ],
            ),
            if (ride.vehiclePlateNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                ride.vehiclePlateNumber!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Request button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: seatsLeft > 0 && !isRequesting
                    ? () => _requestToJoin(ride)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  disabledBackgroundColor: _accent.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: isRequesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        seatsLeft > 0 ? 'Request to Join' : 'No Seats',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeRow(IconData icon, Color iconColor, String label, String value) {
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
                      fontSize: 13, fontWeight: FontWeight.w600, color: _navy)),
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
// Simple status view shown after a passenger sends a ride request.
// Polls for status changes.
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
    while (_isPolling && mounted && _currentRequest.isPending) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Ride Request Status'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
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
                  color: _navy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _statusMessage(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              if (_currentRequest.isPending)
                const CircularProgressIndicator(color: _accent),
              if (_currentRequest.isAccepted)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, 'accepted');
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (_currentRequest.isRejected)
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
          color: Colors.orange.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.hourglass_top,
            size: 40, color: Colors.orange.shade400),
      );
    } else if (_currentRequest.isAccepted) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_circle, size: 40, color: _accent),
      );
    } else {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          shape: BoxShape.circle,
        ),
        child:
            Icon(Icons.cancel, size: 40, color: Colors.red.shade400),
      );
    }
  }

  String _statusTitle() {
    if (_currentRequest.isPending) return 'Request Pending';
    if (_currentRequest.isAccepted) return 'Request Accepted! 🎉';
    return 'Request Declined';
  }

  String _statusMessage() {
    if (_currentRequest.isPending) {
      return 'Your request has been sent to the driver.\nPlease wait for them to respond.';
    }
    if (_currentRequest.isAccepted) {
      return 'The driver has accepted your request!\nYou have been added to the ride.';
    }
    return 'Unfortunately the driver declined your request.\nYou can try requesting another ride.';
  }
}

