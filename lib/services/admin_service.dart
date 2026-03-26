import 'dart:convert';

import '../models/admin_driver_profile.dart';
import '../models/admin_feedback.dart';
import '../models/admin_report.dart';
import '../models/admin_user.dart';
import 'api_client.dart';

class AdminService {
  static Future<List<AdminUser>> getAllUsers({String? role}) async {
    final query = (role == null || role.isEmpty) ? '' : '?role=$role';
    final response = await ApiClient.get('/admin/users$query');

    if (response.statusCode == 200) {
      final list = _extractList(response.body);
      return list
          .whereType<Map<String, dynamic>>()
          .map(AdminUser.fromJson)
          .toList();
    }

    throw Exception(_extractErrorMessage(response.body, 'Failed to load users'));
  }

  static Future<AdminUser> updateUserStatus({
    required int userId,
    required String status,
  }) async {
    final response = await ApiClient.put(
      '/admin/users/$userId/status',
      body: {'status': status},
    );

    if (response.statusCode == 200) {
      return AdminUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception(_extractErrorMessage(response.body, 'Failed to update user status'));
  }

  static Future<List<AdminDriverProfile>> getPendingDrivers() async {
    final response = await ApiClient.get('/admin/drivers/pending');

    if (response.statusCode == 200) {
      final list = _extractList(response.body);
      return list
          .whereType<Map<String, dynamic>>()
          .map(AdminDriverProfile.fromJson)
          .toList();
    }

    throw Exception(_extractErrorMessage(response.body, 'Failed to load pending drivers'));
  }

  static Future<AdminDriverProfile> approveDriver({
    required int driverProfileId,
    required String accountStatus,
    String? remarks,
  }) async {
    final body = <String, dynamic>{
      'accountStatus': accountStatus,
    };
    if (remarks != null && remarks.trim().isNotEmpty) {
      body['remarks'] = remarks.trim();
    }

    final response = await ApiClient.put(
      '/admin/drivers/$driverProfileId/approve',
      body: body,
    );

    if (response.statusCode == 200) {
      return AdminDriverProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception(_extractErrorMessage(response.body, 'Failed to update driver status'));
  }

  static Future<List<AdminReport>> getAllReports({String? status}) async {
    final query = (status == null || status.isEmpty) ? '' : '?status=$status';
    final response = await ApiClient.get('/admin/reports$query');

    if (response.statusCode == 200) {
      final list = _extractList(response.body);
      return list
          .whereType<Map<String, dynamic>>()
          .map(AdminReport.fromJson)
          .toList();
    }

    throw Exception(_extractErrorMessage(response.body, 'Failed to load reports'));
  }

  static Future<AdminReport> updateReportStatus({
    required int reportId,
    required String status,
  }) async {
    final response = await ApiClient.put(
      '/admin/reports/$reportId/status',
      body: {'status': status},
    );

    if (response.statusCode == 200) {
      return AdminReport.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception(_extractErrorMessage(response.body, 'Failed to update report status'));
  }

  static Future<List<AdminFeedback>> getAllFeedback() async {
    final response = await ApiClient.get('/admin/feedback');

    if (response.statusCode == 200) {
      final list = _extractList(response.body);
      return list
          .whereType<Map<String, dynamic>>()
          .map(AdminFeedback.fromJson)
          .toList();
    }

    throw Exception(_extractErrorMessage(response.body, 'Failed to load feedback'));
  }

  static List<dynamic> _extractList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      for (final key in ['data', 'items', 'content']) {
        final candidate = decoded[key];
        if (candidate is List) return candidate;
      }
    }
    return const [];
  }

  static String _extractErrorMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['errorMessage']?.toString() ??
            decoded['messages']?.toString() ??
            decoded['message']?.toString() ??
            fallback;
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }
}

