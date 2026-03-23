import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/config/app_config.dart';
import '../services/payment_service.dart';
import '../utils/snackbar_helper.dart';

/// Screen that loads the PayHere Preapproval card-entry page inside an
/// in-app WebView for card tokenization.
///
/// Flow:
/// 1. Generate order_id → call backend for MD5 hash + merchantId.
/// 2. Build a hidden HTML form with all required PayHere POST fields.
/// 3. Load the HTML into the WebView via `loadHtmlString`.
/// 4. JavaScript auto-submits the form → WebView navigates to PayHere.
/// 5. PayHere's hosted card-entry page renders **inside** the WebView.
/// 6. After the user submits, PayHere redirects to return_url / cancel_url
///    which the NavigationDelegate intercepts.
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
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hashError = false;

  // PayHere sandbox preapproval endpoint
  static const String _payherePreapproveUrl =
      'https://sandbox.payhere.lk/pay/preapprove';

  // Intercepted by NavigationDelegate — never actually loaded in a browser
  static const String _returnUrl = 'https://ridemate.app/payment-return';
  static const String _cancelUrl = 'https://ridemate.app/payment-cancel';

  @override
  void initState() {
    super.initState();
    _initPreapproval();
  }

  // ─── Prepare hash & load PayHere inside WebView ─────────────────

  Future<void> _initPreapproval() async {

    final orderId =
        'PREAPPROVE_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';
    const currency = 'LKR';

    // ── Step 1: Get hash + merchantId from backend ──────────────────
    Map<String, String> hashData;
    try {
      hashData = await PaymentService.getPreapprovalHash(
        orderId: orderId,
        currency: currency,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'Server took too long to respond',
        ),
      );
    } catch (e) {
      dev.log('[AddCardScreen] Hash error: $e', name: 'AddCardScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hashError = true;
        });
        SnackBarHelper.showError(context, 'Failed to prepare payment: $e');
      }
      return;
    }

    final hash = hashData['hash'] ?? '';
    final merchantId = hashData['merchantId'] ?? '';
    final amount = hashData['amount'] ?? '0.00';
    final notifyUrl = '${AppConfig.baseUrl}/payment/notify';

    // ── Step 2: Build HTML form that auto-submits to PayHere ────────
    final html = _buildAutoSubmitHtml(
      merchantId: merchantId,
      returnUrl: _returnUrl,
      cancelUrl: _cancelUrl,
      notifyUrl: notifyUrl,
      orderId: orderId,
      currency: currency,
      amount: amount,
      hash: hash,
    );

    // ── Step 3: Log all values being sent to PayHere ───────────────
    dev.log(
      '\n──────── PayHere Preapproval Fields ────────\n'
      'merchant_id  : $merchantId\n'
      'order_id     : $orderId\n'
      'items        : RideMate Card Setup\n'
      'currency     : $currency\n'
      'amount       : $amount\n'
      'first_name   : ${widget.firstName}\n'
      'last_name    : ${widget.lastName}\n'
      'email        : ${widget.email}\n'
      'phone        : ${widget.phone}\n'
      'address      : N/A\n'
      'city         : Colombo\n'
      'country      : Sri Lanka\n'
      'return_url   : $_returnUrl\n'
      'cancel_url   : $_cancelUrl\n'
      'notify_url   : $notifyUrl\n'
      'hash         : $hash\n'
      'custom_1     : ${widget.userId}\n'
      '────────────────────────────────────────────',
      name: 'PayHere',
    );

    // ── Step 4: Initialise WebView and load the HTML ────────────────
    _initWebView(html);
  }

  void _initWebView(String html) {
    final controller = WebViewController();

    // setJavaScriptMode and setNavigationDelegate are not implemented
    // by webview_flutter_web (iframe). JS is always on in iframes, so
    // we only call these on native mobile platforms.
    if (!kIsWeb) {
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            dev.log(
              '[AddCardScreen] WebView error: ${error.description}',
              name: 'AddCardScreen',
            );
          },
          onNavigationRequest: (request) {
            final url = request.url;
            dev.log('[AddCardScreen] Navigating: $url', name: 'AddCardScreen');

            // ── Intercept return URL → card saved successfully ──
            if (url.contains('payment-return') ||
                url.contains('payment_return')) {
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }

            // ── Intercept cancel URL → user cancelled ──
            if (url.contains('payment-cancel') ||
                url.contains('payment_cancel')) {
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );
    }

    controller.loadHtmlString(html);
    _controller = controller;

    if (mounted) setState(() {});
  }

  // ─── Build the HTML form that POSTs to PayHere ──────────────────

  String _buildAutoSubmitHtml({
    required String merchantId,
    required String returnUrl,
    required String cancelUrl,
    required String notifyUrl,
    required String orderId,
    required String currency,
    required String amount,
    required String hash,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      display: flex; justify-content: center; align-items: center;
      min-height: 100vh; margin: 0; background: #f5f5f5;
    }
    .loader { text-align: center; color: #666; }
    .spinner {
      width: 40px; height: 40px; margin: 0 auto 16px;
      border: 4px solid #e0e0e0; border-top: 4px solid #169F7E;
      border-radius: 50%; animation: spin 0.8s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div class="loader">
    <div class="spinner"></div>
    <p>Loading PayHere...</p>
  </div>

  <form id="payhere_form" method="POST" action="$_payherePreapproveUrl">
    <input type="hidden" name="merchant_id"  value="$merchantId">
    <input type="hidden" name="return_url"   value="$returnUrl">
    <input type="hidden" name="cancel_url"   value="$cancelUrl">
    <input type="hidden" name="notify_url"   value="$notifyUrl">
    <input type="hidden" name="order_id"     value="$orderId">
    <input type="hidden" name="items"        value="RideMate Card Setup">
    <input type="hidden" name="currency"     value="$currency">
    <input type="hidden" name="amount"       value="$amount">
    <input type="hidden" name="first_name"   value="${widget.firstName}">
    <input type="hidden" name="last_name"    value="${widget.lastName}">
    <input type="hidden" name="email"        value="${widget.email}">
    <input type="hidden" name="phone"        value="${widget.phone}">
    <input type="hidden" name="address"      value="N/A">
    <input type="hidden" name="city"         value="Colombo">
    <input type="hidden" name="country"      value="Sri Lanka">
    <input type="hidden" name="hash"         value="$hash">
    <input type="hidden" name="custom_1"     value="${widget.userId}">
  </form>

  <script>document.getElementById("payhere_form").submit();</script>
</body>
</html>
''';
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
    // Error state (hash failed or unsupported platform)
    if (_hashError) {
      return _buildErrorView();
    }

    // WebView ready — show it with loading overlay
    if (_controller != null) {
      return Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    // Still fetching hash from backend
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
              'Could not connect to the payment server.\n'
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hashError = false;
                    _controller = null;
                  });
                  _initPreapproval();
                },
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
          ],
        ),
      ),
    );
  }
}
