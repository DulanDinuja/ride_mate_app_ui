import 'package:flutter/material.dart';

import '../models/cost_split_response.dart';
import '../services/ride_service.dart';

/// Displays the full segment-based cost-split breakdown for a ride.
/// Can receive an already-loaded [CostSplitResponse] via constructor
/// or load one by [rideDetailId].
class CostSplitScreen extends StatefulWidget {
  final int? rideDetailId;
  final CostSplitResponse? initialData;
  final bool isDriver;

  const CostSplitScreen({
    super.key,
    this.rideDetailId,
    this.initialData,
    this.isDriver = false,
  });

  @override
  State<CostSplitScreen> createState() => _CostSplitScreenState();
}

class _CostSplitScreenState extends State<CostSplitScreen> {
  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _cream = Color(0xFFFFFFF0);
  static const Color _cardBg = Color(0xFFF7F8F4);

  CostSplitResponse? _data;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _data = widget.initialData;
    } else if (widget.rideDetailId != null) {
      _loadCostSplit();
    }
  }

  Future<void> _loadCostSplit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await RideService.getCostSplit(widget.rideDetailId!);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recalculate() async {
    final id = _data?.rideDetailId ?? widget.rideDetailId;
    if (id == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await RideService.recalculateCostSplit(id);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Cost Split Breakdown'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        actions: [
          if (widget.isDriver && _data != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Recalculate',
              onPressed: _isLoading ? null : _recalculate,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _accent),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCostSplit,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_data == null) {
      return const Center(
        child: Text('No cost split data available.'),
      );
    }
    return _buildContent(_data!);
  }

  Widget _buildContent(CostSplitResponse data) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Summary card ──
        _buildSummaryCard(data),
        const SizedBox(height: 20),

        // ── Segment breakdown ──
        if (data.segments.isNotEmpty) ...[
          _buildSectionHeader(
              'Route Segments', Icons.route_rounded, _accent),
          const SizedBox(height: 10),
          ...data.segments.map(_buildSegmentCard),
          const SizedBox(height: 20),
        ],

        // ── Passenger costs ──
        if (data.passengerCosts.isNotEmpty) ...[
          _buildSectionHeader(
              'Passenger Costs', Icons.people_rounded, Colors.blue),
          const SizedBox(height: 10),
          ...data.passengerCosts.map(_buildPassengerCard),
          const SizedBox(height: 20),
        ],

        // ── Driver effective cost ──
        _buildDriverCostCard(data),
      ],
    );
  }

  Widget _buildSummaryCard(CostSplitResponse data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF040F1B), Color(0xFF0A2540)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'RIDE COST SUMMARY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white60,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          // Total cost
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'LKR ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
                TextSpan(
                  text: data.totalRideCost.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatPill(
                Icons.straighten_rounded,
                '${data.totalRideDistance.toStringAsFixed(1)} km',
              ),
              _buildStatPill(
                Icons.speed_rounded,
                'LKR ${data.perKmRate.toStringAsFixed(0)}/km',
              ),
              _buildStatPill(
                Icons.people_alt_rounded,
                '${data.totalPassengers} pax',
              ),
            ],
          ),
          if (data.driverStartCity != null) ...[
            const SizedBox(height: 12),
            Text(
              'From: ${data.driverStartCity}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
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
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentCard(SegmentDetail seg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segment header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.15),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${seg.segmentOrder}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${seg.startLabel ?? 'Point ${seg.segmentOrder}'} → ${seg.endLabel ?? 'Point ${seg.segmentOrder + 1}'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Details row
          Row(
            children: [
              _buildDetailChip(
                  Icons.straighten, '${seg.distanceKm.toStringAsFixed(1)} km'),
              const SizedBox(width: 8),
              _buildDetailChip(
                  Icons.people, '${seg.riderCount} rider${seg.riderCount > 1 ? 's' : ''}'),
              const SizedBox(width: 8),
              _buildDetailChip(Icons.attach_money,
                  'LKR ${seg.segmentCost.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 8),
          // Cost per rider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Each rider pays: LKR ${seg.costPerRider.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.black54),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCard(PassengerCostDetail pax) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.15)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.withOpacity(0.12),
            child: const Icon(Icons.person, color: Colors.blue, size: 20),
          ),
          title: Text(
            '${pax.startCity ?? 'Pickup'} → ${pax.endCity ?? 'Drop'}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _navy,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${pax.passengerRideDistance.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'LKR ${pax.totalPassengerCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            if (pax.segmentBreakdown.isNotEmpty) ...[
              const Divider(),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Segment Breakdown:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...pax.segmentBreakdown.map((seg) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.1),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${seg.segmentOrder}',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${seg.startLabel ?? ''} → ${seg.endLabel ?? ''}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black87),
                          ),
                        ),
                        Text(
                          '${seg.riderCount}p × ${seg.distanceKm.toStringAsFixed(1)}km',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black45),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LKR ${seg.passengerShareForSegment.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _accent,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCostCard(CostSplitResponse data) {
    final totalSaved = data.totalRideCost - data.driverEffectiveCost;
    final savingsPct = data.totalRideCost > 0
        ? (totalSaved / data.totalRideCost * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent.withOpacity(0.08),
            _accent.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car,
                    color: _accent, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Driver Effective Cost',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You Pay',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'LKR ${data.driverEffectiveCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                ],
              ),
              if (data.totalPassengers > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'You Save',
                        style: TextStyle(
                            fontSize: 11,
                            color: _accent.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'LKR ${totalSaved.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _accent,
                        ),
                      ),
                      Text(
                        '${savingsPct.toStringAsFixed(0)}% off',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _accent.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (data.totalPassengers > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: data.driverEffectiveCost / data.totalRideCost,
                minHeight: 6,
                backgroundColor: _accent.withOpacity(0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(_accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Original: LKR ${data.totalRideCost.toStringAsFixed(0)} → '
              'You pay only ${(data.driverEffectiveCost / data.totalRideCost * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ],
      ),
    );
  }
}

