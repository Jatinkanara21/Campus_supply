import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class GitHubImageUploadService {
  static const String endpoint = String.fromEnvironment(
    'IMAGE_UPLOAD_API',
    defaultValue: 'https://REPLACE-WITH-YOUR-WORKER.workers.dev/upload-image',
  );

  static Future<String> upload({
    required String folder,
    required String fileName,
    required String contentType,
    required Uint8List imageBytes,
  }) async {
    if (endpoint.contains('REPLACE-WITH-YOUR-WORKER')) {
      throw Exception(
        'IMAGE_UPLOAD_API is not configured. Build with --dart-define=IMAGE_UPLOAD_API=https://YOUR-WORKER.workers.dev/upload-image',
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in as an admin.');
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Could not obtain Firebase authentication token.');
    }

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'folder': folder,
            'fileName': fileName,
            'contentType': contentType,
            'base64': base64Encode(imageBytes),
          }),
        )
        .timeout(const Duration(seconds: 90));

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['error']?.toString() ?? 'GitHub image upload failed (${response.statusCode}).',
      );
    }

    final imagePath = data['imagePath']?.toString();
    if (imagePath == null || imagePath.isEmpty) {
      throw Exception('GitHub upload succeeded but no asset path was returned.');
    }

    return imagePath;
  }
}
