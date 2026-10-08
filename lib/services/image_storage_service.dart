import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageStorageService {
  ImageStorageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> upload({
    required Uint8List bytes,
    required String folder,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('The selected image is empty.');
    }

    if (bytes.length > 10 * 1024 * 1024) {
      throw Exception('Image is larger than 10 MB. Please choose a smaller image.');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Please sign in as an admin before uploading an image.');
    }

    final safe = fileName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child(
      'catalog/$folder/$timestamp-$safe',
    );

    final metadata = SettableMetadata(
      contentType: _contentType(safe),
      cacheControl: 'public,max-age=31536000',
    );

    try {
      await ref.putData(bytes, metadata);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'storage/unauthorized':
          throw Exception(
            'Firebase Storage denied this upload. Make sure your Firebase Storage rules are deployed and your user has role "admin".',
          );
        case 'storage/bucket-not-found':
          throw Exception(
            'Firebase Storage bucket is not available. Enable Cloud Storage for the Firebase project first.',
          );
        case 'storage/quota-exceeded':
          throw Exception('Firebase Storage quota has been exceeded.');
        case 'storage/canceled':
          throw Exception('Image upload was canceled.');
        case 'storage/unknown':
          throw Exception(
            'Firebase Storage returned an unknown error. Check the Firebase Storage console.',
          );
        default:
          throw Exception('Firebase Storage error (${e.code}): ${e.message ?? 'upload failed'}.');
      }
    }
  }

  static String _contentType(String name) {
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    if (name.endsWith('.svg')) return 'image/svg+xml';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }
}
