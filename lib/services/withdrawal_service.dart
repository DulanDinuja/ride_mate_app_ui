import 'dart:convert';
import 'dart:developer' as dev;

import '../models/api_exception.dart';
import '../models/api_response.dart';
import '../models/withdrawal_request.dart';
import 'api_client.dart';

/// Handles all withdrawal-related API calls (authenticated).
///
/// Maps to backend WithdrawalController endpoints:
///   POST /withdrawal
///   PUT  /withdrawal/{id}/status
///   GET  /withdrawal/driver/{driverProfileId}
///   GET  /withdrawal/pending
class WithdrawalService {
  /// POST /withdrawal — create a new withdrawal request
  static Future<ApiResponse> createWithdrawalRequest({
    required int driverProfileId,
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    String currency = 'LKR',
  }) async {
    try {
      final body = <String, dynamic>{
        'driverProfileId': driverProfileId,
        'amount': amount,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountHolderName': accountHolderName,
        'currency': currency,
      };

      final response = await ApiClient.post('/withdrawal', body: body);
      dev.log('[WithdrawalService] createWithdrawal ${response.statusCode}',
          name: 'WithdrawalService');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['messages'];
          if (msg != null) throw ApiException(msg.toString());
        }
        throw Exception('Failed to create withdrawal request');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /withdrawal/driver/{driverProfileId}
  static Future<List<WithdrawalRequest>> getByDriverProfile(
      int driverProfileId) async {
    try {
      final response =
          await ApiClient.get('/withdrawal/driver/$driverProfileId');
      dev.log(
          '[WithdrawalService] getByDriverProfile ${response.statusCode}',
          name: 'WithdrawalService');

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) =>
                WithdrawalRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['messages'];
          if (msg != null) throw ApiException(msg.toString());
        }
        throw Exception('Failed to fetch withdrawal requests');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// PUT /withdrawal/{id}/status — admin action to approve/reject
  static Future<ApiResponse> updateWithdrawalStatus({
    required int withdrawalId,
    required String status,
    String? remarks,
  }) async {
    try {
      final body = <String, dynamic>{
        'status': status,
      };
      if (remarks != null) body['remarks'] = remarks;

      final response = await ApiClient.put(
        '/withdrawal/$withdrawalId/status',
        body: body,
      );
      dev.log(
          '[WithdrawalService] updateWithdrawalStatus ${response.statusCode}',
          name: 'WithdrawalService');

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['messages'];
          if (msg != null) throw ApiException(msg.toString());
        }
        throw Exception('Failed to update withdrawal status');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /withdrawal/pending — admin view of all pending withdrawals
  static Future<List<WithdrawalRequest>> getAllPending() async {
    try {
      final response = await ApiClient.get('/withdrawal/pending');
      dev.log('[WithdrawalService] getAllPending ${response.statusCode}',
          name: 'WithdrawalService');

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) =>
                WithdrawalRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['messages'];
          if (msg != null) throw ApiException(msg.toString());
        }
        throw Exception('Failed to fetch pending withdrawals');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}

