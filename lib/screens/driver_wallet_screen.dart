import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/driver_wallet.dart';
import '../models/driver_wallet_transaction.dart';
import '../models/ride_income_detail.dart';
import '../services/driver_wallet_service.dart';
import '../utils/snackbar_helper.dart';
import 'withdrawal_request_screen.dart';
import 'withdrawal_history_screen.dart';

/// Driver wallet dashboard showing balance summary, transaction history,
/// ride income breakdown, and withdrawal access.
///
/// Maps to:
///   GET /driver-wallet/{driverProfileId}
///   GET /driver-wallet/{driverProfileId}/transactions
///   GET /driver-wallet/{driverProfileId}/ride-income
class DriverWalletScreen extends StatefulWidget {
  final int driverProfileId;

  const DriverWalletScreen({super.key, required this.driverProfileId});

  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DriverWallet? _wallet;
  List<DriverWalletTransaction> _transactions = [];
  List<RideIncomeDetail> _earnings = [];
  bool _isLoading = true;

  final _currencyFormat =
      NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2);
  final _dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DriverWalletService.getWalletSummary(widget.driverProfileId),
        DriverWalletService.getWalletTransactions(widget.driverProfileId),
        DriverWalletService.getRideIncomeDetails(widget.driverProfileId),
      ]);
      _wallet = results[0] as DriverWallet;
      _transactions = results[1] as List<DriverWalletTransaction>;
      _earnings = results[2] as List<RideIncomeDetail>;
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Withdrawal History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WithdrawalHistoryScreen(
                    driverProfileId: widget.driverProfileId),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildBalanceCard(),
                    _buildSummaryRow(),
                    _buildWithdrawButton(),
                    _buildTabs(),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Balance Card ────────────────────────────────────────────────

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF040F1B), Color(0xFF1A3A5C)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF040F1B).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                _wallet?.currency ?? 'LKR',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _currencyFormat.format(_wallet?.availableBalance ?? 0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (_wallet?.driverName != null)
            Text(
              _wallet!.driverName!,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
        ],
      ),
    );
  }

  // ─── Summary Row ─────────────────────────────────────────────────

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildSummaryItem(
            'Total Earnings',
            _wallet?.totalEarnings ?? 0,
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildSummaryItem(
            'Commission',
            _wallet?.totalCommission ?? 0,
            Icons.percent,
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildSummaryItem(
            'Withdrawn',
            _wallet?.totalWithdrawn ?? 0,
            Icons.account_balance,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, double amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Withdraw Button ─────────────────────────────────────────────

  Widget _buildWithdrawButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => WithdrawalRequestScreen(
                  driverProfileId: widget.driverProfileId,
                  availableBalance: _wallet?.availableBalance ?? 0,
                  currency: _wallet?.currency ?? 'LKR',
                ),
              ),
            );
            if (result == true) _loadData();
          },
          icon: const Icon(Icons.account_balance_wallet),
          label: const Text(
            'Withdraw Funds',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF169F7E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Tabs ────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF040F1B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF169F7E),
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Ride Earnings'),
          ],
        ),
        SizedBox(
          // Give enough height for the tab content
          height: (_tabController.index == 0
                      ? _transactions.length
                      : _earnings.length) *
                  120.0 +
              100,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionsList(),
              _buildEarningsList(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Transactions Tab ────────────────────────────────────────────

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return _buildTabEmpty('No transactions yet', Icons.swap_horiz);
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final txn = _transactions[index];
        return _buildTransactionTile(txn);
      },
    );
  }

  Widget _buildTransactionTile(DriverWalletTransaction txn) {
    Color color;
    IconData icon;
    String label;

    if (txn.isEarning) {
      color = Colors.green;
      icon = Icons.arrow_downward;
      label = 'Ride Earning';
    } else if (txn.isWithdrawal) {
      color = Colors.red;
      icon = Icons.arrow_upward;
      label = 'Withdrawal';
    } else if (txn.isCommission) {
      color = Colors.orange;
      icon = Icons.percent;
      label = 'Commission';
    } else {
      color = Colors.blue;
      icon = Icons.swap_horiz;
      label = txn.transactionType ?? 'Transaction';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (txn.description != null)
              Text(txn.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (txn.createdDate != null)
              Text(_dateFormat.format(txn.createdDate!),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${txn.isEarning ? '+' : '-'} ${_currencyFormat.format(txn.netAmount ?? txn.grossAmount ?? 0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: txn.isEarning ? Colors.green : Colors.red,
              ),
            ),
            if (txn.balanceAfter != null)
              Text(
                'Bal: ${_currencyFormat.format(txn.balanceAfter!)}',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Earnings Tab ────────────────────────────────────────────────

  Widget _buildEarningsList() {
    if (_earnings.isEmpty) {
      return _buildTabEmpty('No earnings yet', Icons.monetization_on_outlined);
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: _earnings.length,
      itemBuilder: (context, index) {
        final earning = _earnings[index];
        return _buildEarningTile(earning);
      },
    );
  }

  Widget _buildEarningTile(RideIncomeDetail earning) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car,
                        size: 18, color: Color(0xFF169F7E)),
                    const SizedBox(width: 8),
                    Text(
                      earning.startCity ?? 'Ride #${earning.rideDetailId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Text(
                  _currencyFormat.format(earning.netEarning ?? 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF169F7E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 12),
            _buildEarningRow('Gross Earning', earning.grossEarning),
            _buildEarningRow('Commission (${earning.commissionPercentage ?? 0}%)',
                earning.commissionAmount, isNegative: true),
            _buildEarningRow('Net Earning', earning.netEarning,
                isBold: true),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${earning.numberOfPassengers ?? 0} passenger(s) • ${earning.totalRideDistance?.toStringAsFixed(1) ?? 0} km',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                if (earning.rideDate != null)
                  Text(
                    DateFormat('MMM dd').format(earning.rideDate!),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningRow(String label, double? value,
      {bool isNegative = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '${isNegative ? '- ' : ''}${_currencyFormat.format(value ?? 0)}',
            style: TextStyle(
              fontSize: 13,
              color: isNegative ? Colors.red[400] : Colors.grey[800],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabEmpty(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

