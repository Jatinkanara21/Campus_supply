import 'package:flutter/material.dart';

class CampusLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const CampusLogo({super.key, this.size = 56, this.showWordmark = false});

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B5BF7), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(size * .28),
        boxShadow: const [
          BoxShadow(color: Color(0x225B5BF7), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * .10,
            child: Icon(Icons.school_rounded, color: Colors.white, size: size * .46),
          ),
          Positioned(
            bottom: size * .08,
            child: Container(
              width: size * .48,
              height: size * .28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * .08),
              ),
              child: Icon(Icons.shopping_bag_rounded, color: const Color(0xFF6D4AFF), size: size * .23),
            ),
          ),
          Positioned(
            right: size * .08,
            top: size * .32,
            child: Container(width: size * .11, height: size * .11, decoration: const BoxDecoration(color: Color(0xFFFBBF24), shape: BoxShape.circle)),
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
        const Text('Campus', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.7, color: Color(0xFF17172B))),
        const Text('Supply', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.7, color: Color(0xFF6D4AFF))),
      ],
    );
  }
}
