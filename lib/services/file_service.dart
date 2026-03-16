import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/api_exception.dart';
import 'api_client.dart';
import 'token_service.dart';

/// Handles file uploads to the ride-mate backend.
///
/// Endpoint: POST /file/upload
/// Authorization: Bearer token attached automatically.
/// Body: multipart/form-data with field name `file`.
class FileService {
  static const String _uploadEndpoint = '/file/upload';

  /// Uploads a single file as bytes.
  ///
  /// [bytes]    — raw file bytes (e.g. from `XFile.readAsBytes()`).
  /// [fileName] — file name including extension (e.g. "license_front.jpg").
  ///
  /// Returns the raw response body string on success (2xx).
  /// Throws [ApiException] on a non-2xx status, or [Exception] on network errors.
  static Future<String> uploadFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final uri = Uri.parse('${ApiClient.baseUrl}$_uploadEndpoint');
      final request = http.MultipartRequest('POST', uri);

      // --- Authorization header (Bearer token) ---
      final authHeader = await TokenService.getAuthorizationHeader();
      if (authHeader != null) {
        request.headers['Authorization'] = authHeader;
      }

      // --- file field ---
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }

      throw ApiException(
        'File upload failed (${response.statusCode}): ${response.body}',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Network error during file upload: $e');
    }
  }

  /// Convenience method to upload multiple files sequentially.
  ///
  /// [files] — map of fileName → bytes.
  /// Returns a map of fileName → response body.
  static Future<Map<String, String>> uploadFiles(
    Map<String, Uint8List> files,
  ) async {
    final results = <String, String>{};
    for (final entry in files.entries) {
      results[entry.key] = await uploadFile(
        bytes: entry.value,
        fileName: entry.key,
      );
    }
    return results;
  }
}