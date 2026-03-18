import 'dart:convert';
import 'dart:typed_data';

import '../models/api_exception.dart';
import 'api_client.dart';

/// Handles file uploads to the ride-mate backend.
///
/// Endpoint: POST /file/upload
/// Authorization: Bearer token attached automatically.
/// Body: multipart/form-data with field name `file`.
///
/// On a 401 the token is refreshed once and the request retried (handled by
/// [ApiClient.multipartPost]).
class FileService {
  static const String _uploadEndpoint = '/file/upload';

  /// Uploads a single file as bytes.
  ///
  /// [bytes]    — raw file bytes (e.g. from `XFile.readAsBytes()`).
  /// [fileName] — file name including extension (e.g. "license_front.jpg").
  ///
  /// Returns the uploaded document ID from the server response.
  /// Throws [ApiException] on a non-2xx status, or [Exception] on network errors.
  static Future<int> uploadFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final response = await ApiClient.multipartPost(
        _uploadEndpoint,
        fileBytes: bytes,
        fileName: fileName,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['id'] as int;
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
  /// Returns a map of fileName → document ID.
  static Future<Map<String, int>> uploadFiles(
    Map<String, Uint8List> files,
  ) async {
    final results = <String, int>{};
    for (final entry in files.entries) {
      results[entry.key] = await uploadFile(
        bytes: entry.value,
        fileName: entry.key,
      );
    }
    return results;
  }
}