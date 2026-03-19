import 'package:flutter/material.dart';

import '../models/cost_split_response.dart';

/// Reusable widget that displays the segment-based cost breakdown for a ride.
///
/// Shows:
/// - Total ride cost and per-km rate
/// - Segment-by-segment breakdown with rider count and cost per rider
/// - Per-passenger cost details
/// - Driver's effective cost (total minus all passenger contributions)
///
/// Used in both [DriverHomeMapScreen] and [UserHomeMapScreen].
class CostBreakdownCard extends StatelessWidget {
  final CostSplitResponse costSplit;
  final bool isDriver;

  /// For passenger view, optionally highlight this user's cost
  final int? currentUserId;

  static const Color _accent = Color(0xFF10B47A);
  static const Color _navy = Color(0xFF02132A);
  static const Color _cardBg = Color(0xFFFFFFF0);

  const CostBreakdownCard({
    super.key,
    required this.costSplit,
    this.isDriver = false,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 16),

          // Summary card
          _buildSummaryCard(),
          const SizedBox(height: 20),

          // Segment breakdown
          if (costSplit.segments.isNotEmpty) ...[
            _buildSectionTitle('Route Segments'),
            const SizedBox(height: 8),
            ...costSplit.segments.map(_buildSegmentTile),
            const SizedBox(height: 20),
          ],

          // Passenger costs
          if (costSplit.passengerCosts.isNotEmpty) ...[
            _buildSectionTitle(
              isDriver ? 'Passenger Contributions' : 'Cost Breakdown',
            ),
            const SizedBox(height: 8),
            ...costSplit.passengerCosts.map(_buildPassengerTile),
          ],

          // Driver effective cost
          if (isDriver) ...[
            const SizedBox(height: 16),
            _buildDriverCostSummary(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long_rounded, color: _accent, size: 24),
        ),
        const SizedBox(width: 12),
        const Text(
          'COST BREAKDOWN',
          style: TextStyle(
            color: Color(0xFFA9AAAC),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${costSplit.totalPassengers ?? 0} rider${(costSplit.totalPassengers ?? 0) != 1 ? 's' : ''}',
            style: const TextStyle(
              color: _accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E3D8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              children: [
                const TextSpan(
                  text: 'LKR ',
                  style: TextStyle(color: _accent),
                ),
                TextSpan(
                  text: _formatCurrency(
                    isDriver
                        ? costSplit.driverEffectiveCost
                        : _getCurrentPassengerCost(),
                  ),
                  style: const TextStyle(color: _navy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isDriver ? 'Your effective cost' : 'Your share',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(
                '${costSplit.totalRideDistance?.toStringAsFixed(1) ?? '0'} km',
                Icons.straighten_rounded,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                'LKR ${costSplit.perKmRate?.toStringAsFixed(0) ?? '0'}/km',
                Icons.speed_rounded,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                'Total: LKR ${_formatCurrency(costSplit.totalRideCost)}',
                Icons.account_balance_wallet_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _navy,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSegmentTile(SegmentDetail segment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Segment visual indicator
          Column(
            children: [
              Icon(Icons.circle, size: 10, color: _accent.withOpacity(0.6)),
              Container(
                width: 2,
                height: 20,
                color: _accent.withOpacity(0.3),
              ),
              const Icon(Icons.circle, size: 10, color: _accent),
            ],
          ),
          const SizedBox(width: 12),

          // Segment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${segment.startLabel ?? 'Point ${segment.segmentOrder}'} → ${segment.endLabel ?? 'Next'}',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${segment.distanceKm?.toStringAsFixed(1) ?? '0'} km • ${segment.riderCount ?? 0} rider${(segment.riderCount ?? 0) != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Cost
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LKR ${_formatCurrency(segment.segmentCost)}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Text(
                'LKR ${_formatCurrency(segment.costPerRider)}/each',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerTile(PassengerCostDetail passenger) {
    final isCurrentUser = currentUserId != null && passenger.userId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? _accent.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser ? _accent.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person, color: _accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${passenger.startCity ?? 'Pickup'} → ${passenger.endCity ?? 'Dropoff'}',
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${passenger.passengerRideDistance?.toStringAsFixed(1) ?? '0'} km',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                'LKR ${_formatCurrency(passenger.totalPassengerCost)}',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // Expanded segment breakdown
          if (passenger.segmentBreakdown.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: passenger.segmentBreakdown.map((seg) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.subdirectory_arrow_right,
                            size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${seg.startLabel ?? ''} → ${seg.endLabel ?? ''} (${seg.distanceKm?.toStringAsFixed(1) ?? '0'} km, ${seg.riderCount ?? 0} riders)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          'LKR ${_formatCurrency(seg.passengerShareForSegment)}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverCostSummary() {
    final totalPassengerPayments = costSplit.passengerCosts.fold<double>(
      0,
      (sum, p) => sum + (p.totalPassengerCost ?? 0),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent.withOpacity(0.1), _accent.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Ride Cost',
                style: TextStyle(color: _navy, fontSize: 13),
              ),
              Text(
                'LKR ${_formatCurrency(costSplit.totalRideCost)}',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Passenger Contributions',
                style: TextStyle(color: _accent, fontSize: 13),
              ),
              Text(
                '- LKR ${_formatCurrency(totalPassengerPayments)}',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'You Pay',
                style: TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'LKR ${_formatCurrency(costSplit.driverEffectiveCost)}',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double? _getCurrentPassengerCost() {
    if (currentUserId == null) return costSplit.totalRideCost;
    final match = costSplit.passengerCosts
        .where((p) => p.userId == currentUserId)
        .toList();
    if (match.isNotEmpty) return match.first.totalPassengerCost;
    return costSplit.totalRideCost;
  }

  String _formatCurrency(double? value) {
    if (value == null) return '0.00';
    return value.toStringAsFixed(2);
  }
}

