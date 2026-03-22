import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/withdrawal_request.dart';
import '../services/withdrawal_service.dart';
import '../utils/snackbar_helper.dart';

/// Displays the driver's withdrawal request history.
///
/// Maps to: GET /withdrawal/driver/{driverProfileId}
class WithdrawalHistoryScreen extends StatefulWidget {
  final int driverProfileId;

  const WithdrawalHistoryScreen({super.key, required this.driverProfileId});

  @override
  State<WithdrawalHistoryScreen> createState() =>
      _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends State<WithdrawalHistoryScreen> {
  List<WithdrawalRequest> _withdrawals = [];
  bool _isLoading = true;
  final _currencyFormat =
      NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2);
  final _dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _withdrawals =
          await WithdrawalService.getByDriverProfile(widget.driverProfileId);
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(WithdrawalRequest w) {
    if (w.isApproved) return Colors.green;
    if (w.isRejected) return Colors.red;
    return Colors.orange;
  }

  IconData _statusIcon(WithdrawalRequest w) {
    if (w.isApproved) return Icons.check_circle;
    if (w.isRejected) return Icons.cancel;
    return Icons.hourglass_empty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawal History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _withdrawals.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
            ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No withdrawal requests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your withdrawal history will appear here',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _withdrawals.length,
      itemBuilder: (context, index) {
        final w = _withdrawals[index];
        return _buildTile(w);
      },
    );
  }

  Widget _buildTile(WithdrawalRequest w) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor(w).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_statusIcon(w),
                      color: _statusColor(w), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currencyFormat.format(w.amount ?? 0),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF040F1B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        w.bankName ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(w).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    w.status ?? 'UNKNOWN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(w),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 12),

            // Bank details
            _buildDetailRow('Account', w.accountNumber),
            _buildDetailRow('Holder', w.accountHolderName),
            if (w.remarks != null && w.remarks!.isNotEmpty)
              _buildDetailRow('Remarks', w.remarks),

            const SizedBox(height: 8),
            if (w.createdDate != null)
              Text(
                _dateFormat.format(w.createdDate!),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF040F1B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

