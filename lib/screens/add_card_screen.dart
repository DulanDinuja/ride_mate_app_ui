import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/config/app_config.dart';
import '../services/payment_service.dart';
import '../utils/snackbar_helper.dart';

/// Screen that opens the PayHere Preapproval page for card tokenization.
///
/// PayHere Preapproval API flow (per official docs):
/// 1. Frontend generates an order_id and calls backend
///    `GET /payment/preapproval-hash` to get the MD5 hash (server-side,
///    protects merchant_secret).
/// 2. An HTML form with all required POST params (including hash) is
///    submitted to `https://sandbox.payhere.lk/pay/preapprove`.
/// 3. User enters card credentials on PayHere's hosted page.
/// 4. PayHere POSTs the result to backend `POST /payment/notify`
///    (notify_url) with customer_token, card details, status, md5sig.
/// 5. Backend verifies md5sig, stores the card token in user_saved_card.
/// 6. User is redirected to return_url → we intercept and pop(true).
///
/// Uses in-app WebView on Android/iOS; falls back to external browser
/// on unsupported platforms (desktop, web).
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
  bool _webViewSupported = false;
  bool _hashError = false;

  // PayHere sandbox preapproval URL
  static const String _payhereSandboxUrl =
      'https://sandbox.payhere.lk/pay/preapprove';

  // Return / cancel URLs — intercepted by NavigationDelegate, never actually loaded
  static const String _returnUrl = 'https://ridemate.app/payment-return';
  static const String _cancelUrl = 'https://ridemate.app/payment-cancel';

  @override
  void initState() {
    super.initState();
    _initPreapproval();
  }

  /// 1. Generate order_id
  /// 2. Call backend to get the server-generated hash
  /// 3. Build the preapproval HTML form and load it in the WebView
  Future<void> _initPreapproval() async {
    final orderId =
        'PREAPPROVE_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';
    const currency = 'LKR';

    // ── Step 1: Get hash from backend ───────────────────────────────
    Map<String, String> hashData;
    try {
      hashData = await PaymentService.getPreapprovalHash(
        orderId: orderId,
        currency: currency,
      );
    } catch (e) {
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

    // ── Step 2: Build the HTML form ─────────────────────────────────
    final html = _buildPreapprovalHtml(
      merchantId: merchantId,
      orderId: orderId,
      currency: currency,
      hash: hash,
    );

    // ── Step 3: Load in WebView or fallback ─────────────────────────
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _initWebView(html);
    } else {
      setState(() {
        _webViewSupported = false;
        _isLoading = false;
      });
    }
  }

  /// Initialise in-app WebView with the preapproval HTML.
  void _initWebView(String html) {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
            onNavigationRequest: (request) {
              final url = request.url;

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
        )
        ..loadRequest(Uri.dataFromString(
          html,
          mimeType: 'text/html',
          encoding: utf8,
        ));

      setState(() => _webViewSupported = true);
    } catch (e) {
      setState(() {
        _webViewSupported = false;
        _isLoading = false;
      });
    }
  }

  /// Build the PayHere Preapproval HTML form with all required POST
  /// parameters per the official documentation.
  String _buildPreapprovalHtml({
    required String merchantId,
    required String orderId,
    required String currency,
    required String hash,
  }) {
    // notify_url must be publicly accessible — backend handles this
    final notifyUrl = '${AppConfig.baseUrl}/payment/notify';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      display: flex; justify-content: center; align-items: center;
      min-height: 100vh; margin: 0; background: #f5f5f5;
    }
    .loader { text-align: center; color: #666; }
    .loader .spinner {
      width: 40px; height: 40px; margin: 0 auto 16px;
      border: 4px solid #e0e0e0; border-top: 4px solid #169F7E;
      border-radius: 50%; animation: spin 0.8s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    .loader p { font-size: 16px; }
  </style>
</head>
<body>
  <div class="loader">
    <div class="spinner"></div>
    <p>Redirecting to PayHere...</p>
  </div>

  <!-- PayHere Preapproval Form — Required POST Parameters -->
  <form id="payhere-form" method="POST" action="$_payhereSandboxUrl">
    <!-- Merchant & URLs -->
    <input type="hidden" name="merchant_id"  value="$merchantId">
    <input type="hidden" name="return_url"   value="$_returnUrl">
    <input type="hidden" name="cancel_url"   value="$_cancelUrl">
    <input type="hidden" name="notify_url"   value="$notifyUrl">

    <!-- Order -->
    <input type="hidden" name="order_id"     value="$orderId">
    <input type="hidden" name="items"        value="RideMate Card Setup">
    <input type="hidden" name="currency"     value="$currency">

    <!-- Customer Details (required by PayHere) -->
    <input type="hidden" name="first_name"   value="${widget.firstName}">
    <input type="hidden" name="last_name"    value="${widget.lastName}">
    <input type="hidden" name="email"        value="${widget.email}">
    <input type="hidden" name="phone"        value="${widget.phone}">
    <input type="hidden" name="address"      value="N/A">
    <input type="hidden" name="city"         value="Colombo">
    <input type="hidden" name="country"      value="Sri Lanka">

    <!-- Hash (generated server-side — required since 2023-01-16) -->
    <input type="hidden" name="hash"         value="$hash">

    <!-- Custom: pass userId so backend notify callback can link the token -->
    <input type="hidden" name="custom_1"     value="${widget.userId}">
  </form>

  <script>document.getElementById('payhere-form').submit();</script>
</body>
</html>
''';
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.parse(_payhereSandboxUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
    // Error fetching hash
    if (_hashError) {
      return _buildErrorView();
    }

    // WebView available and loaded
    if (_webViewSupported && _controller != null) {
      return Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    // Still loading hash from backend
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

    // Fallback for desktop / web
    return _buildFallbackView();
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
              'Could not connect to the server to prepare the secure payment form. '
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

  Widget _buildFallbackView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_browser,
                size: 64, color: Color(0xFF169F7E)),
            const SizedBox(height: 20),
            const Text(
              'Add Card via Browser',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF040F1B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'In-app WebView is not available on this platform.\n'
              'Tap below to open PayHere in your browser.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _openInExternalBrowser,
                icon: const Icon(Icons.launch),
                label: const Text('Open PayHere'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF169F7E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("I've completed card setup"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
