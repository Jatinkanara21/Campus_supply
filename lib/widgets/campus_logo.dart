import 'package:flutter/material.dart';

class CampusLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const CampusLogo({super.key, this.size = 56, this.showWordmark = false});

  static const deepForest = Color(0xFF0B2E20);
  static const emerald = Color(0xFF1F7A5A);
  static const mint = Color(0xFFA7D7C5);
  static const warmGold = Color(0xFFD8B76A);
  static const warmTaupe = Color(0xFF8A7B68);

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deepForest, emerald],
        ),
        borderRadius: BorderRadius.circular(size * .28),
        border: Border.all(color: warmGold.withValues(alpha: .55)),
        boxShadow: const [
          BoxShadow(color: Color(0x553F8F70), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * .08,
            child: Icon(Icons.school_rounded, color: mint, size: size * .46),
          ),
          Positioned(
            bottom: size * .08,
            child: Container(
              width: size * .48,
              height: size * .28,
              decoration: BoxDecoration(
                color: warmTaupe,
                borderRadius: BorderRadius.circular(size * .08),
                border: Border.all(color: warmGold, width: 1),
              ),
              child: Icon(Icons.shopping_bag_rounded, color: deepForest, size: size * .23),
            ),
          ),
          Positioned(
            right: size * .08,
            top: size * .32,
            child: Container(
              width: size * .11,
              height: size * .11,
              decoration: const BoxDecoration(color: warmGold, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        const Text(
          'Campus',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.7, color: mint),
        ),
        const Text(
          ' Supply',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.7, color: warmGold),
        ),
      ],
    );
  }
}
