import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class ImageStorageService {
  ImageStorageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> upload({
    required Uint8List bytes,
    required String folder,
    required String fileName,
  }) async {
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

    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  static String _contentType(String name) {
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    if (name.endsWith('.svg')) return 'image/svg+xml';
    return 'image/jpeg';
  }
}
