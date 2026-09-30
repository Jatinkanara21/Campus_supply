import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});
  @override State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const cream = Color(0xFFFAF8F3), ink = Color(0xFF172033), blue = Color(0xFF2563EB), yellow = Color(0xFFFACC15), muted = Color(0xFF707681);
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final product = args is Map<String, dynamic> ? args : <String, dynamic>{};
    final name = (product['name'] ?? 'Product').toString();
    final description = (product['description'] ?? 'A campus essential designed for everyday student use.').toString();
    final price = product['price'];
    final imageUrl = (product['imageUrl'] ?? '').toString();

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Product Details', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              final id = product['id']?.toString();
              if (uid == null || id == null) {
                Navigator.pushNamed(context, '/login');
                return;
              }
              await FirestoreDatabase.instance.toggleWishlist(uid: uid, productId: id);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wishlist updated')));
            },
            icon: const Icon(Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
        children: [
          Container(
            height: 320,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFFE7E2D9))),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_rounded, color: blue, size: 120))
                : const Icon(Icons.inventory_2_rounded, color: blue, size: 120),
          ),
          const SizedBox(height: 20),
          Text(name, style: const TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -.7)),
          const SizedBox(height: 7),
          Row(children: [
            const Icon(Icons.star_rounded, color: Color(0xFFF4B400), size: 19),
            const SizedBox(width: 4),
            Text((product['rating'] ?? 'New').toString(), style: const TextStyle(color: muted, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text(price == null ? '₹0' : '₹$price', style: const TextStyle(color: blue, fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 22),
          const Text('About this product', style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(description, style: const TextStyle(color: muted, height: 1.5)),
          const SizedBox(height: 20),
          Row(children: [
            const Text('Quantity', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(onPressed: () => setState(() => quantity = quantity > 1 ? quantity - 1 : 1), icon: const Icon(Icons.remove_circle_outline)),
            Text(quantity.toString(), style: const TextStyle(color: ink, fontWeight: FontWeight.w900)),
            IconButton(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add_circle_outline)),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                final id = product['id']?.toString();
                if (uid == null) {
                  Navigator.pushNamed(context, '/login');
                  return;
                }
                if (id == null) return;
                await FirestoreDatabase.instance.addToCart(uid: uid, productId: id, quantity: quantity);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
              },
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Add to Cart'),
            ),
          ),
        ],
      ),
    );
  }
}
