import 'dart:convert';
import 'dart:developer' as dev;

import '../models/api_exception.dart';
import '../models/api_response.dart';
import '../models/payment_transaction.dart';
import '../models/saved_card.dart';
import 'api_client.dart';

/// Handles all payment-related API calls (authenticated).
///
/// Maps to backend PaymentController endpoints:
///   POST /payment/charge
///   GET  /payment/saved-cards/{userId}
///   GET  /payment/transactions/{userId}
///   GET  /payment/payhere-config
class PaymentService {
  // ─── PayHere Config ───────────────────────────────────────────────

  /// GET /payment/payhere-config
  /// Returns {merchantId, merchantSecret, sandbox} for the PayHere SDK.
  /// Falls back to AppConfig values if the endpoint doesn't exist yet.
  static Future<Map<String, String>> getPayHereConfig() async {
    try {
      final response = await ApiClient.get('/payment/payhere-config');
      dev.log('[PaymentService] getPayHereConfig ${response.statusCode}',
          name: 'PaymentService');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return data.map((k, v) => MapEntry(k, v.toString()));
      }
      // If endpoint doesn't exist, return empty — caller uses AppConfig
      return {};
    } catch (_) {
      return {};
    }
  }

  // ─── Preapproval Hash ─────────────────────────────────────────────

  /// GET /payment/preapproval-hash?orderId=...&currency=LKR
  /// Returns {hash, merchantId, amount} generated server-side.
  static Future<Map<String, String>> getPreapprovalHash({
    required String orderId,
    String currency = 'LKR',
  }) async {
    try {
      final response = await ApiClient.get(
        '/payment/preapproval-hash?orderId=$orderId&currency=$currency',
      );
      dev.log('[PaymentService] getPreapprovalHash ${response.statusCode}',
          name: 'PaymentService');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return data.map((k, v) => MapEntry(k, v.toString()));
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['messages'];
          if (msg != null) throw ApiException(msg.toString());
        }
        throw Exception('Failed to generate payment hash');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ─── Charge Passenger ──────────────────────────────────────────────

  /// POST /payment/charge
  static Future<ApiResponse> chargePassenger({
    required int userId,
    required int rideDetailId,
    required double amount,
    String currency = 'LKR',
    String? itemName,
  }) async {
    try {
      final body = <String, dynamic>{
        'userId': userId,
        'rideDetailId': rideDetailId,
        'amount': amount,
        'currency': currency,
      };
      if (itemName != null) body['itemName'] = itemName;

      final response = await ApiClient.post('/payment/charge', body: body);
      dev.log('[PaymentService] chargePassenger ${response.statusCode}',
          name: 'PaymentService');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['messages'];
          if (msg != null) throw ApiException(msg.toString());
        }
        throw Exception('Failed to charge passenger');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /payment/saved-cards/{userId}
  static Future<List<SavedCard>> getSavedCards(int userId) async {
    try {
      final response = await ApiClient.get('/payment/saved-cards/$userId');
      dev.log('[PaymentService] getSavedCards ${response.statusCode}',
          name: 'PaymentService');

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) => SavedCard.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['messages'];
          if (msg != null) throw ApiException(msg.toString());
        }
        throw Exception('Failed to fetch saved cards');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /payment/transactions/{userId}
  static Future<List<PaymentTransaction>> getTransactions(int userId) async {
    try {
      final response = await ApiClient.get('/payment/transactions/$userId');
      dev.log('[PaymentService] getTransactions ${response.statusCode}',
          name: 'PaymentService');

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) =>
                PaymentTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['messages'];
          if (msg != null) throw ApiException(msg.toString());
        }
        throw Exception('Failed to fetch transactions');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}

