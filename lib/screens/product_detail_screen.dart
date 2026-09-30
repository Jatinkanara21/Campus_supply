import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});
  @override State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const cream = Color(0xFFFAF8F3), ink = Color(0xFF172033), blue = Color(0xFF2563EB), muted = Color(0xFF6B7280), border = Color(0xFFE7E2D9);
  int quantity = 1;
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final product = args is Map<String, dynamic> ? args : <String, dynamic>{};
    final name = (product['name'] ?? 'Product').toString();
    final description = (product['description'] ?? 'Campus essential for everyday student life.').toString();
    final imageUrl = (product['imageUrl'] ?? '').toString().trim();
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final rating = (product['rating'] ?? 'New').toString();
    final category = (product['category'] ?? 'Campus essential').toString();

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Product', style: TextStyle(fontWeight: FontWeight.w900)), actions: [
        IconButton(onPressed: () => Navigator.pushNamed(context, '/cart'), icon: const Icon(Icons.shopping_bag_outlined)),
      ]),
      body: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;
        final image = _image(imageUrl);
        final details = _details(context, product, name, description, price, rating, category);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 34 : 18, 8, wide ? 34 : 18, 36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: image), const SizedBox(width: 34), Expanded(child: details),
            ]) : Column(children: [image, const SizedBox(height: 22), details]),
          ),
        );
      }),
    );
  }

  Widget _image(String url) => Container(
    height: 440, clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: border)),
    child: url.isEmpty ? const Center(child: Icon(Icons.inventory_2_rounded, color: blue, size: 110)) : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, color: blue, size: 80))),
  );

  Widget _details(BuildContext context, Map<String, dynamic> product, String name, String description, double price, String rating, String category) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(20)), child: Text(category.toUpperCase(), style: const TextStyle(color: blue, fontSize: 10, fontWeight: FontWeight.w900))),
      const SizedBox(height: 13),
      Text(name, style: const TextStyle(color: ink, fontSize: 32, height: 1.05, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Row(children: [const Icon(Icons.star_rounded, color: Color(0xFFF4B400), size: 20), const SizedBox(width: 4), Text(rating, style: const TextStyle(color: muted, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 18),
      Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(color: blue, fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 22),
      const Text('About this product', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text(description, style: const TextStyle(color: muted, height: 1.55)),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
        child: Row(children: [
          const Text('Quantity', style: TextStyle(color: ink, fontWeight: FontWeight.w800)), const Spacer(),
          IconButton(onPressed: () => setState(() => quantity = quantity > 1 ? quantity - 1 : 1), icon: const Icon(Icons.remove_circle_outline)),
          Text('${quantity}', style: const TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w900)),
          IconButton(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add_circle_outline)),
        ]),
      ),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, height: 56, child: FilledButton.icon(onPressed: saving ? null : () => _addToCart(context, product), icon: const Icon(Icons.shopping_bag_outlined), label: Text(saving ? 'Adding...' : 'Add to cart'))),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(onPressed: () => Navigator.pushNamed(context, '/shop'), icon: const Icon(Icons.arrow_back_rounded), label: const Text('Continue shopping'))),
    ],
  );

  Future<void> _addToCart(BuildContext context, Map<String, dynamic> product) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final id = product['id']?.toString();
    if (uid == null) { Navigator.pushNamed(context, '/login'); return; }
    if (id == null) return;
    setState(() => saving = true);
    try {
      await FirestoreDatabase.instance.addToCart(uid: uid, productId: id, quantity: quantity);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
    } finally { if (mounted) setState(() => saving = false); }
  }
}
