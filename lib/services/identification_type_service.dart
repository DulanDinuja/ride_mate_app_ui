import 'dart:convert';

import '../models/identification_type.dart';
import 'api_client.dart';

class IdentificationTypeService {
  static Future<List<IdentificationType>> getActiveIdentificationTypes() async {
    try {
      final response = await ApiClient.get(
        '/identification-type/get-identification-type/status/ACTIVE',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load identification types');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Invalid identification type response');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(IdentificationType.fromJson)
          .where((item) => item.name.trim().isNotEmpty)
          .toList();
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}

