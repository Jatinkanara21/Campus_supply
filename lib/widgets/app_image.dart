import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders both local Flutter assets and remote image URLs safely.
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

  String get _normalizedAssetPath {
    var value = (source ?? '').trim().replaceAll('\\', '/');

    // Keep the canonical asset folder used by pubspec.yaml.
    if (value.startsWith('assets/images/')) {
      value = 'assets/' + value.substring('assets/images/'.length);
    }

    return value;
  }

  Widget _fallback(BuildContext context) {
    return fallback ??
        const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 42,
            color: Color(0xFF2563EB),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final raw = (source ?? '').trim();
    if (raw.isEmpty) return _fallback(context);

    if (_isAsset) {
      final path = _normalizedAssetPath;

      if (path.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(
          path,
          fit: fit,
          placeholderBuilder: (_) =>
              placeholder ?? const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }

      return Image.asset(
        path,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    return Image.network(
      raw,
      fit: fit,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return placeholder ??
            const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (_, __, ___) => _fallback(context),
    );
  }
}
