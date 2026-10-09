import 'package:flutter/material.dart';

class CampusLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const CampusLogo({super.key, this.size = 56, this.showWordmark = false});

  static const blue = Color(0xFF3157D5);
  static const cream = Color(0xFFF5F7FB);
  static const yellow = Color(0xFFFFC66D);
  static const ink = Color(0xFF172554);

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: blue,
        borderRadius: BorderRadius.circular(size * .24),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * .16,
            child: Icon(Icons.school_rounded, color: cream, size: size * .43),
          ),
          Positioned(
            bottom: size * .11,
            child: Container(
              width: size * .48,
              height: size * .25,
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(size * .07),
              ),
              child: Icon(Icons.shopping_bag_rounded, color: ink, size: size * .21),
            ),
          ),
          Positioned(
            right: size * .11,
            top: size * .25,
            child: Container(
              width: size * .12,
              height: size * .12,
              decoration: const BoxDecoration(
                color: yellow,
                shape: BoxShape.circle,
              ),
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
        const SizedBox(width: 10),
        const Text(
          'Campus',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            color: ink,
          ),
        ),
        const Text(
          ' Supply',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            color: blue,
          ),
        ),
      ],
    );
  }
}
