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

    // Flutter Web can resize/re-encode a picked image, so the original
    // filename extension is not guaranteed to match the actual bytes.
    final detected = _detectImage(bytes);
    if (detected == null) {
      throw Exception('The selected file is not a supported image.');
    }

    final baseName = fileName
        .trim()
        .replaceAll(RegExp(r'\.[^.]*$'), '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    final safeBase = baseName.isEmpty ? 'image' : baseName;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child(
      'catalog/$folder/$timestamp-$safeBase.${detected.extension}',
    );

    final metadata = SettableMetadata(
      contentType: detected.contentType,
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
          throw Exception(
            'Firebase Storage error (${e.code}): ${e.message ?? 'upload failed'}.',
          );
      }
    }
  }

  static _ImageType? _detectImage(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return const _ImageType('jpg', 'image/jpeg');
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return const _ImageType('png', 'image/png');
    }

    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38 &&
        (bytes[4] == 0x37 || bytes[4] == 0x39) &&
        bytes[5] == 0x61) {
      return const _ImageType('gif', 'image/gif');
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return const _ImageType('webp', 'image/webp');
    }

    return null;
  }
}

class _ImageType {
  final String extension;
  final String contentType;

  const _ImageType(this.extension, this.contentType);
}
