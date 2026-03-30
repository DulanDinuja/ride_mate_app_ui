import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ride_request.dart';
import '../services/ride_request_service.dart';
import '../widgets/custom_back_button.dart';

/// Screen where the driver sees incoming passenger ride requests
/// and can accept or reject them.
class DriverRideRequestsScreen extends StatefulWidget {
  final int driverProfileId;
  final int rideDetailId;
  /// Maximum passengers the vehicle can hold (from vehicle type rules).
  final int maxSeats;
  /// Number of passengers already accepted on this ride.
  final int currentPassengers;

  const DriverRideRequestsScreen({
    super.key,
    required this.driverProfileId,
    required this.rideDetailId,
    this.maxSeats = 3,
    this.currentPassengers = 0,
  });

  @override
  State<DriverRideRequestsScreen> createState() =>
      _DriverRideRequestsScreenState();
}

class _DriverRideRequestsScreenState extends State<DriverRideRequestsScreen> {
  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _cream = Color(0xFFFFFFF0);

  List<RideRequest> _requests = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  final Set<int> _processingIds = {};

  /// Tracks how many requests have been accepted during this session
  /// so capacity check stays accurate without a network round-trip.
  int _sessionAccepted = 0;

  int get _effectivePassengers =>
      widget.currentPassengers + _sessionAccepted;

  bool get _isFull => _effectivePassengers >= widget.maxSeats;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadRequests(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    try {
      final requests = await RideRequestService.getDriverPendingRequests(
          widget.driverProfileId);
      if (mounted) {
        setState(() {
          _requests = requests;
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

  Future<void> _acceptRequest(RideRequest request) async {
    // ── Capacity guard ───────────────────────────────────────────
    if (_isFull) {
      _showSnackBar(
        'Vehicle is full ($_effectivePassengers/${widget.maxSeats} seats). '
        'Cannot accept more passengers.',
        isError: true,
      );
      return;
    }

    setState(() => _processingIds.add(request.id));
    try {
      final updated = await RideRequestService.acceptRequest(request.id);
      if (mounted) {
        setState(() => _sessionAccepted++);
        final costText = updated.estimatedCost != null
            ? ' Cost: LKR ${updated.estimatedCost!.toStringAsFixed(2)}'
            : '';
        _showSnackBar(
            '${request.passengerFullName} added to your ride!$costText');
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(request.id));
    }
  }

  Future<void> _rejectRequest(RideRequest request) async {
    setState(() => _processingIds.add(request.id));
    try {
      await RideRequestService.rejectRequest(request.id);
      if (mounted) {
        _showSnackBar('Request from ${request.passengerFullName} declined.');
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(request.id));
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ride Requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              'Seats: $_effectivePassengers / ${widget.maxSeats}'
              '${_isFull ? ' · FULL' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: _isFull ? Colors.red.shade200 : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Capacity bar ──────────────────────────────────────
          _buildCapacityBar(),
          // ── Request list ──────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildCapacityBar() {
    final pct = widget.maxSeats == 0
        ? 0.0
        : (_effectivePassengers / widget.maxSeats).clamp(0.0, 1.0);

    return Container(
      color: _navy,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isFull
                    ? '🚫 No available seats'
                    : '${widget.maxSeats - _effectivePassengers} seat${widget.maxSeats - _effectivePassengers != 1 ? 's' : ''} available',
                style: TextStyle(
                  fontSize: 12,
                  color: _isFull ? Colors.red.shade300 : Colors.white70,
                ),
              ),
              // Seat icons
              Row(
                children: List.generate(widget.maxSeats, (i) {
                  final filled = i < _effectivePassengers;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      filled ? Icons.event_seat : Icons.event_seat_outlined,
                      size: 16,
                      color: filled
                          ? (_isFull ? Colors.red.shade400 : _accent)
                          : Colors.white24,
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isFull ? Colors.red.shade400 : _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _requests.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_error != null && _requests.isEmpty) {
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
                onPressed: _loadRequests,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No pending ride requests',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'New requests will appear here\nwhen passengers want to join your ride.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) =>
            _buildRequestCard(_requests[index]),
      ),
    );
  }

  Widget _buildRequestCard(RideRequest request) {
    final isProcessing = _processingIds.contains(request.id);

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
            // Passenger info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _accent.withOpacity(0.1),
                  child: request.passengerProfileImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            request.passengerProfileImageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, color: _accent),
                          ),
                        )
                      : const Icon(Icons.person, color: _accent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.passengerFullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                      if (request.passengerPhone != null)
                        Text(
                          request.passengerPhone!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                // Distance badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${request.passengerRideDistance.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Passenger route
            Row(
              children: [
                Icon(Icons.radio_button_checked,
                    size: 16, color: Colors.blue.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.startCity ?? 'Pickup location',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _navy),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Container(
                  width: 2, height: 12, color: Colors.grey.shade300),
            ),
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 16, color: Colors.red.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.endCity ?? 'Drop location',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _navy),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Accept / Reject buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed:
                          isProcessing ? null : () => _rejectRequest(request),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Decline',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: (isProcessing || _isFull)
                          ? null
                          : () => _acceptRequest(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        disabledBackgroundColor: _isFull
                            ? Colors.grey.shade300
                            : _accent.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isFull ? 'Seat Full' : 'Accept',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _isFull
                                    ? Colors.grey.shade600
                                    : Colors.white,
                              ),
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
}

