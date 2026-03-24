import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';

import '../core/config/app_config.dart';
import '../services/payment_service.dart';
import '../utils/snackbar_helper.dart';

/// Screen that initiates PayHere Preapproval for card tokenization using
/// the **PayHere Flutter SDK** (native, no WebView).
///
/// Flow:
/// 1. Fetch PayHere merchant credentials (from backend or AppConfig).
/// 2. Build a payment object with preapproval parameters.
/// 3. Call `PayHere.startPayment()` — the SDK opens its own native UI.
/// 4. On success, PayHere sends a server notification to `notify_url`
///    and the SDK returns a `paymentId` to the app.
/// 5. Pop with `true` so the parent screen refreshes saved cards.
class AddCardScreen extends StatefulWidget {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  const AddCardScreen({
    super.key,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  bool _isLoading = true;
  bool _configError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startPreapproval();
  }

  // ─── Fetch config & launch PayHere SDK ──────────────────────────

  Future<void> _startPreapproval() async {
    // PayHere mobile SDK is Android/iOS only
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _configError = true;
          _errorMessage = 'PayHere SDK is not supported on web.\n'
              'Please use the mobile app to add a card.';
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _configError = false;
      _errorMessage = '';
    });

    // ── Step 1: Resolve merchant credentials ──────────────────────
    String merchantId;
    String merchantSecret;
    bool sandbox;

    try {
      // Try fetching from backend first (recommended for security)
      final config = await PaymentService.getPayHereConfig();

      merchantId = config['merchantId'] ??
          config['merchant_id'] ??
          AppConfig.payhereMerchantId;

      merchantSecret = config['merchantSecret'] ??
          config['merchant_secret'] ??
          AppConfig.payhereMerchantSecret;

      sandbox = (config['sandbox'] ?? AppConfig.payhereSandbox.toString())
              .toString()
              .toLowerCase() ==
          'true';
    } catch (e) {
      // Fallback to AppConfig values
      merchantId = AppConfig.payhereMerchantId;
      merchantSecret = AppConfig.payhereMerchantSecret;
      sandbox = AppConfig.payhereSandbox;
    }

    // Validate credentials
    if (merchantId.isEmpty || merchantSecret.isEmpty) {
      dev.log(
        '[AddCardScreen] Missing PayHere credentials. '
        'merchantId: ${merchantId.isEmpty ? "EMPTY" : "SET"}, '
        'merchantSecret: ${merchantSecret.isEmpty ? "EMPTY" : "SET"}',
        name: 'PayHere',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _configError = true;
          _errorMessage =
              'PayHere payment credentials are not configured.\n\n'
              'Pass them via --dart-define flags:\n'
              '  PAYHERE_MERCHANT_ID=your_id\n'
              '  PAYHERE_MERCHANT_SECRET=your_secret';
        });
      }
      return;
    }

    // ── Step 2: Generate a unique order ID ────────────────────────
    final orderId =
        'PREAPPROVE_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';
    final notifyUrl = '${AppConfig.baseUrl}/payment/notify';

    // ── Step 3: Build the PayHere payment object ──────────────────
    final paymentObject = {
      "sandbox": sandbox,
      "preapprove": true,  // ← CRITICAL: triggers preapproval flow
      "merchant_id": merchantId,
      "merchant_secret": merchantSecret,
      "notify_url": notifyUrl,
      "order_id": orderId,
      "items": "RideMate Card Setup",
      "currency": "LKR",
      "amount": "30.00",
      "first_name": widget.firstName,
      "last_name": widget.lastName,
      "email": widget.email,
      "phone": widget.phone,
      "address": "N/A",
      "city": "Colombo",
      "country": "Sri Lanka",
      "custom_1": widget.userId.toString(),
      "custom_2": "",
    };

    // ── Step 4: Log all values being sent to PayHere ──────────────
    dev.log(
      '\n──────── PayHere SDK Preapproval Fields ────────\n'
      'sandbox      : $sandbox\n'
      'merchant_id  : $merchantId\n'
      'order_id     : $orderId\n'
      'items        : RideMate Card Setup\n'
      'currency     : LKR\n'
      'amount       : 0.00\n'
      'first_name   : ${widget.firstName}\n'
      'last_name    : ${widget.lastName}\n'
      'email        : ${widget.email}\n'
      'phone        : ${widget.phone}\n'
      'notify_url   : $notifyUrl\n'
      'custom_1     : ${widget.userId}\n'
      '────────────────────────────────────────────────',
      name: 'PayHere',
    );

    if (mounted) setState(() => _isLoading = false);

    // ── Step 5: Launch PayHere SDK ────────────────────────────────
    try {
      PayHere.startPayment(
        paymentObject,
        // ── onCompleted ──
        (paymentId) {
          dev.log(
            '[AddCardScreen] Preapproval success. PaymentId: $paymentId',
            name: 'PayHere',
          );
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        },
        // ── onError ──
        (error) {
          dev.log(
            '[AddCardScreen] Preapproval error: $error',
            name: 'PayHere',
          );
          if (mounted) {
            SnackBarHelper.showError(context, 'Payment failed: $error');
            setState(() {
              _configError = true;
              _errorMessage = 'Payment failed: $error';
            });
          }
        },
        // ── onDismissed ──
        () {
          dev.log(
            '[AddCardScreen] Preapproval dismissed by user',
            name: 'PayHere',
          );
          if (mounted) {
            Navigator.of(context).pop(false);
          }
        },
      );
    } on MissingPluginException catch (e) {
      dev.log(
        '[AddCardScreen] MissingPluginException: $e\n'
        'Did you do a full rebuild after adding payhere_mobilesdk_flutter?\n'
        'Run: flutter clean && flutter pub get && flutter run',
        name: 'PayHere',
      );
      if (mounted) {
        setState(() {
          _configError = true;
          _errorMessage =
              'PayHere SDK failed to load.\n\n'
              'Please fully restart the app:\n'
              '1. Stop the app completely\n'
              '2. Run: flutter clean\n'
              '3. Run: flutter run';
        });
      }
    } catch (e) {
      dev.log('[AddCardScreen] Unexpected error: $e', name: 'PayHere');
      if (mounted) {
        setState(() {
          _configError = true;
          _errorMessage = 'Unexpected error: $e';
        });
      }
    }
  }

  // ─── UI ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment Card'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Error state
    if (_configError) {
      return _buildErrorView();
    }

    // Loading — waiting for config fetch or SDK to open
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparing secure payment...'),
          ],
        ),
      );
    }

    // SDK has been launched — show a lighter waiting state
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Preparing secure payment...'),
          SizedBox(height: 8),
          Text(
            'PayHere payment gateway will open shortly',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Unable to Prepare Payment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Could not connect to the payment server.\n'
                      'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _startPreapproval,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF169F7E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
