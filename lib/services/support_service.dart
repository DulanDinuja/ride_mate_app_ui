import 'dart:convert';

import 'api_client.dart';

/// Handles Report a Problem and Give Feedback API calls.
class SupportService {
  // ── Report a Problem ────────────────────────────────────────────────────────

  /// POST /user-reports
  /// Submits a problem report for the given user.
  static Future<Map<String, dynamic>> submitReport({
    required int userId,
    required String category,
    required String subject,
    required String description,
  }) async {
    final response = await ApiClient.post(
      '/user-reports',
      body: {
        'userId': userId,
        'category': category,
        'subject': subject,
        'description': description,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['errorMessage'] ?? 'Failed to submit report');
    }
  }

  // ── Give Feedback ──────────────────────────────────────────────────────────

  /// POST /user-feedback
  /// Submits star-rated feedback for the given user.
  static Future<Map<String, dynamic>> submitFeedback({
    required int userId,
    required int rating,
    required String category,
    required String feedbackText,
  }) async {
    final response = await ApiClient.post(
      '/user-feedback',
      body: {
        'userId': userId,
        'rating': rating,
        'category': category,
        'feedbackText': feedbackText,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['errorMessage'] ?? 'Failed to submit feedback');
    }
  }
}

