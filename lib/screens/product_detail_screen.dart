import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const forest = Color(0xFF0B2E20), dark = Color(0xFF124D36), emerald = Color(0xFF1F7A5A), mint = Color(0xFFA7D7C5), gold = Color(0xFFD8B76A), taupe = Color(0xFF8A7B68), espresso = Color(0xFF2A211B);
  int quantity = 1;
  int selectedColor = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: forest,
      appBar: AppBar(title: const Text('Product Details'), actions: [IconButton(onPressed: () => Navigator.pushNamed(context, '/wishlist'), icon: const Icon(Icons.favorite_border_rounded))]),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 30), children: [
        Container(height: 300, decoration: BoxDecoration(gradient: const LinearGradient(colors: [dark, emerald]), borderRadius: BorderRadius.circular(30), border: Border.all(color: gold.withValues(alpha: .6))), child: const Center(child: Icon(Icons.backpack_rounded, size: 150, color: Color(0xFFD6B26E)))),
        const SizedBox(height: 20),
        Row(children: [Expanded(child: Text('Campus Pro Backpack', style: TextStyle(color: mint, fontSize: 26, fontWeight: FontWeight.w900))), Icon(Icons.favorite_border_rounded, color: gold)]),
        const SizedBox(height: 8),
        const Row(children: [Icon(Icons.star_rounded, color: gold, size: 19), SizedBox(width: 4), Text('4.8  •  256 reviews', style: TextStyle(color: taupe))]),
        const SizedBox(height: 16),
        const Text('₹1,499', style: TextStyle(color: gold, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        _section('Select Color'),
        const SizedBox(height: 10),
        Row(children: List.generate(5, (i) => GestureDetector(onTap: () => setState(() => selectedColor = i), child: Container(margin: const EdgeInsets.only(right: 12), width: 38, height: 38, decoration: BoxDecoration(color: [const Color(0xFF356B4A), const Color(0xFF315A7D), const Color(0xFF8A4B4B), const Color(0xFF8A7B68), const Color(0xFF26352F)][i], shape: BoxShape.circle, border: Border.all(color: selectedColor == i ? gold : sage, width: selectedColor == i ? 2 : 1))))),
        const SizedBox(height: 22),
        _section('About Product'),
        const SizedBox(height: 8),
        const Text('Spacious, stylish and durable campus backpack with organized compartments, water-resistant material and a dedicated laptop sleeve.', style: TextStyle(color: taupe, height: 1.5)),
        const SizedBox(height: 20),
        Row(children: [const Text('Quantity', style: TextStyle(color: mint, fontWeight: FontWeight.w700)), const Spacer(), _qtyButton(Icons.remove, () => setState(() => quantity = quantity > 1 ? quantity - 1 : 1)), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('$quantity', style: const TextStyle(color: mint, fontWeight: FontWeight.w800))), _qtyButton(Icons.add, () => setState(() => quantity++))]),
        const SizedBox(height: 22),
        SizedBox(height: 54, child: ElevatedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart'))), icon: const Icon(Icons.shopping_bag_outlined), label: const Text('Add to Cart'))),
      ]),
    );
  }

  Widget _section(String text) => Text(text, style: const TextStyle(color: mint, fontSize: 17, fontWeight: FontWeight.w800));
  Widget _qtyButton(IconData icon, VoidCallback onTap) => IconButton(onPressed: onTap, style: IconButton.styleFrom(backgroundColor: dark, foregroundColor: gold), icon: Icon(icon));
  static const sage = Color(0xFF5F8F7A);
}
