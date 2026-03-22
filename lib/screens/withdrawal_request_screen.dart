import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/withdrawal_service.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/custom_button.dart';

/// Form screen for a driver to submit a withdrawal request.
///
/// Maps to: POST /withdrawal
class WithdrawalRequestScreen extends StatefulWidget {
  final int driverProfileId;
  final double availableBalance;
  final String currency;

  const WithdrawalRequestScreen({
    super.key,
    required this.driverProfileId,
    required this.availableBalance,
    this.currency = 'LKR',
  });

  @override
  State<WithdrawalRequestScreen> createState() =>
      _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState extends State<WithdrawalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  bool _isSubmitting = false;

  final _currencyFormat =
      NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2);

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      SnackBarHelper.showError(context, 'Please enter a valid amount');
      return;
    }
    if (amount > widget.availableBalance) {
      SnackBarHelper.showError(context, 'Insufficient balance');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await WithdrawalService.createWithdrawalRequest(
        driverProfileId: widget.driverProfileId,
        amount: amount,
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        accountHolderName: _accountHolderController.text.trim(),
        currency: widget.currency,
      );

      if (mounted) {
        SnackBarHelper.showSuccess(
            context, 'Withdrawal request submitted successfully');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw Funds')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF169F7E).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF169F7E).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A5565),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currencyFormat.format(widget.availableBalance),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF169F7E),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Amount field
              const Text(
                'Withdrawal Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF040F1B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixText: '${widget.currency} ',
                  prefixIcon: const Icon(Icons.money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (amount > widget.availableBalance) {
                    return 'Exceeds available balance';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Bank name
              const Text(
                'Bank Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF040F1B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Bank of Ceylon',
                  prefixIcon: const Icon(Icons.account_balance),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bank name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Account number
              const Text(
                'Account Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF040F1B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter account number',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Account number is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Account holder name
              const Text(
                'Account Holder Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF040F1B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accountHolderController,
                decoration: InputDecoration(
                  hintText: 'Enter account holder name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Account holder name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Submit button
              CustomButton(
                text: 'Submit Withdrawal Request',
                onPressed: _submit,
                isLoading: _isSubmitting,
                backgroundColor: const Color(0xFF169F7E),
              ),

              const SizedBox(height: 16),

              // Info note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: Colors.amber[800]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Withdrawal requests are reviewed by the admin team. '
                        'Processing may take 1–3 business days.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

