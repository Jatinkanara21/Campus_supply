import 'package:flutter/material.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});
  static const forest = Color(0xFF0B2E20);
  static const dark = Color(0xFF124D36);
  static const mint = Color(0xFFA7D7C5);
  static const gold = Color(0xFFD8B76A);
  static const taupe = Color(0xFF8A7B68);
  static const sage = Color(0xFF5F8F7A);

  @override
  Widget build(BuildContext context) {
    final products = [
      (Icons.headphones_rounded, 'Wireless Headphones', '₹1,299', const Color(0xFF83B8D8)),
      (Icons.menu_book_rounded, 'Premium Notebook', '₹149', const Color(0xFFD6B26E)),
      (Icons.water_drop_rounded, 'Steel Water Bottle', '₹699', const Color(0xFFB7D88B)),
      (Icons.backpack_rounded, 'Campus Pro Backpack', '₹1,499', const Color(0xFFD38F62)),
      (Icons.calculate_rounded, 'Scientific Calculator', '₹899', const Color(0xFF8FA7D8)),
    ];

    return Scaffold(
      backgroundColor: forest,
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [TextButton(onPressed: () {}, child: const Text('Edit'))],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final p = products[i];
          final accent = p.$4;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sage.withValues(alpha: .45)),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: forest, borderRadius: BorderRadius.circular(16)),
                  child: Icon(p.$1, size: 38, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.$2, style: const TextStyle(color: mint, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(p.$3, style: const TextStyle(color: gold, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text('In stock', style: TextStyle(color: sage, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_rounded, color: gold)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.shopping_cart_outlined, color: mint)),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Move All to Cart'),
          ),
        ),
      ),
    );
  }
}
