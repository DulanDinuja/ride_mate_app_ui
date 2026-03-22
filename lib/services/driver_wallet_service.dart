import 'dart:convert';
import 'dart:developer' as dev;

import '../models/api_exception.dart';
import '../models/api_response.dart';
import '../models/driver_wallet.dart';
import '../models/driver_wallet_transaction.dart';
import '../models/ride_income_detail.dart';
import 'api_client.dart';

/// Handles all driver wallet API calls (authenticated).
///
/// Maps to backend DriverWalletController endpoints:
///   GET  /driver-wallet/{driverProfileId}
///   GET  /driver-wallet/{driverProfileId}/transactions
///   GET  /driver-wallet/{driverProfileId}/ride-income
///   POST /driver-wallet/credit
class DriverWalletService {
  /// GET /driver-wallet/{driverProfileId}
  static Future<DriverWallet> getWalletSummary(int driverProfileId) async {
    try {
      final response =
          await ApiClient.get('/driver-wallet/$driverProfileId');
      dev.log('[DriverWalletService] getWalletSummary ${response.statusCode}',
          name: 'DriverWalletService');

      if (response.statusCode == 200) {
        return DriverWallet.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['messages'];
          if (msg != null) throw ApiException(msg.toString());
        }
        throw Exception('Failed to fetch wallet summary');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /driver-wallet/{driverProfileId}/transactions
  static Future<List<DriverWalletTransaction>> getWalletTransactions(
      int driverProfileId) async {
    try {
      final response =
          await ApiClient.get('/driver-wallet/$driverProfileId/transactions');
      dev.log(
          '[DriverWalletService] getWalletTransactions ${response.statusCode}',
          name: 'DriverWalletService');

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) =>
                DriverWalletTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['messages'];
          if (msg != null) throw ApiException(msg.toString());
        }
        throw Exception('Failed to fetch wallet transactions');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /driver-wallet/{driverProfileId}/ride-income
  static Future<List<RideIncomeDetail>> getRideIncomeDetails(
      int driverProfileId) async {
    try {
      final response =
          await ApiClient.get('/driver-wallet/$driverProfileId/ride-income');
      dev.log(
          '[DriverWalletService] getRideIncomeDetails ${response.statusCode}',
          name: 'DriverWalletService');

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) =>
                RideIncomeDetail.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['messages'];
          if (msg != null) throw ApiException(msg.toString());
        }
        throw Exception('Failed to fetch ride income details');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// POST /driver-wallet/credit
  static Future<ApiResponse> creditRideEarning({
    required int driverProfileId,
    required int rideDetailId,
    required double grossAmount,
    int? driverEarningId,
    String currency = 'LKR',
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{
        'driverProfileId': driverProfileId,
        'rideDetailId': rideDetailId,
        'grossAmount': grossAmount,
        'currency': currency,
      };
      if (driverEarningId != null) body['driverEarningId'] = driverEarningId;
      if (description != null) body['description'] = description;

      final response =
          await ApiClient.post('/driver-wallet/credit', body: body);
      dev.log(
          '[DriverWalletService] creditRideEarning ${response.statusCode}',
          name: 'DriverWalletService');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        if (error is Map) {
          final msg = error['message'] ?? error['messages'];
          if (msg != null) throw ApiException(msg.toString());
        }
        throw Exception('Failed to credit ride earning');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}

