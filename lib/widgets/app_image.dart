import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders bundled assets, normal web URLs and Firebase Storage references.
class AppImage extends StatelessWidget {
  final String? source;
  final BoxFit fit;
  final Widget? fallback;
  final Widget? placeholder;

  const AppImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.fallback,
    this.placeholder,
  });

  bool get _isAsset {
    final value = (source ?? '').trim().replaceAll('\\', '/');
    return value.startsWith('assets/');
  }

  bool get _isSvg {
    final value = (source ?? '').trim().toLowerCase();
    if (value.startsWith('assets/')) return value.endsWith('.svg');
    final uri = Uri.tryParse(value);
    return uri != null && uri.path.endsWith('.svg');
  }

  bool get _isFirebaseStorageReference {
    final value = (source ?? '').trim();
    return value.startsWith('gs://') ||
        (!value.startsWith('http://') &&
            !value.startsWith('https://') &&
            value.startsWith('catalog/'));
  }

  String get _normalizedAssetPath {
    return (source ?? '').trim().replaceAll('\\', '/');
  }

  Widget _fallback(BuildContext context) {
    return fallback ??
        const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 42,
            color: Color(0xFF3157D5),
          ),
        );
  }

  Widget _networkImage(String url, BuildContext context) {
    if (_isSvg) {
      return SvgPicture.network(
        url,
        fit: fit,
        placeholderBuilder: (_) =>
            placeholder ??
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Image.network(
      url,
      fit: fit,
      gaplessPlayback: true,
      // Use the normal Flutter web image pipeline for Firebase download URLs.
      // The HTML-element strategy can stay in a perpetual loading state on
      // some GitHub Pages/browser combinations even when the URL is valid.
      webHtmlElementStrategy: WebHtmlElementStrategy.never,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return placeholder ??
            const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (_, __, ___) => _fallback(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = (source ?? '').trim();
    if (raw.isEmpty) return _fallback(context);

    if (_isAsset) {
      final path = _normalizedAssetPath;

      if (_isSvg) {
        return SvgPicture.asset(
          path,
          fit: fit,
          placeholderBuilder: (_) =>
              placeholder ??
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }

      return Image.asset(
        path,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    if (_isFirebaseStorageReference) {
      final storageRef = raw.startsWith('gs://')
          ? FirebaseStorage.instance.refFromURL(raw)
          : FirebaseStorage.instance
              .ref()
              .child(raw);
      return FutureBuilder<String>(
        future: storageRef.getDownloadURL(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return placeholder ??
                const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _fallback(context);
          }
          return _networkImage(snapshot.data!, context);
        },
      );
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _networkImage(raw, context);
    }

    return _fallback(context);
  }
}
