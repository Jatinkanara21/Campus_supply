import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Uploads catalog images into the GitHub repository through a secure
/// Firebase Cloud Function. The GitHub token never reaches the Flutter app.
class ImageStorageService {
  ImageStorageService._();

  static const String _uploadEndpoint =
      'https://us-central1-campus-supply-abcbf.cloudfunctions.net/uploadImageToGitHub';

  static Future<String> upload({
    required Uint8List bytes,
    required String folder,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('The selected image is empty.');
    }

    if (bytes.length > 8 * 1024 * 1024) {
      throw Exception(
        'Image is larger than 8 MB. Please choose a smaller image.',
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception(
        'Please sign in as an admin before uploading an image.',
      );
    }

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Unable to authenticate the image upload.');
    }

    final response = await http
        .post(
          Uri.parse(_uploadEndpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'fileName': fileName,
            'folder': folder,
            'base64': base64Encode(bytes),
          }),
        )
        .timeout(const Duration(seconds: 120));

    Map<String, dynamic> payload = <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
      }
    } catch (_) {
      // Fall through to the HTTP status handling below.
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = (payload['error'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty
            ? message
            : 'GitHub image upload failed (HTTP ${response.statusCode}).',
      );
    }

    final url = (payload['url'] ?? '').toString().trim();
    if (url.isEmpty) {
      throw Exception(
        'GitHub upload succeeded but no image URL was returned.',
      );
    }

    return url;
  }
}
