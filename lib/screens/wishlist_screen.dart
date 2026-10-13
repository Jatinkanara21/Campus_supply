import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/app_image.dart';
import '../database/firestore_database.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});
  static const cream = Color(0xFFFAF8F3), ink = Color(0xFF172033), blue = Color(0xFF3157D5), coral = Color(0xFFFF8066), muted = Color(0xFF64748B), border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Scaffold(backgroundColor: cream, appBar: AppBar(title: const Text('Wishlist')), body: _state(context, Icons.lock_outline_rounded, 'Sign in to view your wishlist', 'Your saved products will be waiting here.', 'Sign in', () => Navigator.pushNamed(context, '/login')));
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Wishlist', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(tooltip: 'Explore products', onPressed: () => Navigator.pushNamed(context, '/shop'), icon: const Icon(Icons.add_shopping_cart_rounded))]),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchWishlist(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _state(context, Icons.cloud_off_outlined, 'Wishlist unavailable', 'Please try again in a moment.');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final wishes = snapshot.data!;
          if (wishes.isEmpty) return _state(context, Icons.favorite_border_rounded, 'Nothing saved yet', 'Tap the heart on products you want to keep.', 'Explore products', () => Navigator.pushNamed(context, '/shop'));
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreDatabase.instance.watchProducts(),
            builder: (context, products) {
              if (products.hasError) return _state(context, Icons.cloud_off_outlined, 'Products unavailable', 'Your wishlist could not be displayed right now.');
              if (!products.hasData) return const Center(child: CircularProgressIndicator());
              final byId = {for (final p in products.data!) p['id'].toString(): p};
              return LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1100 ? 3 : constraints.maxWidth >= 700 ? 2 : 1;
                return Center(child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: wishes.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: columns == 1 ? 2.15 : 1.35),
                    itemBuilder: (context, i) {
                      final id = wishes[i]['productId']?.toString();
                      final product = byId[id];
                      final image = (product?['imageUrl'] ?? '').toString();
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: border)),
                        child: Row(children: [
                          Expanded(flex: 4, child: Container(clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: const Color(0xFFF7F5F0), borderRadius: BorderRadius.circular(16)), child: AppImage(source: image, fit: BoxFit.contain, fallback: const Center(child: Icon(Icons.inventory_2_rounded, color: blue, size: 35))))),
                          const SizedBox(width: 13),
                          Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text((product?['name'] ?? 'Product').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontWeight: FontWeight.w900, height: 1.25)),
                            const Spacer(),
                            Text('₹${((product?['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}', style: const TextStyle(color: blue, fontSize: 18, fontWeight: FontWeight.w900)),
                            Row(children: [
                              IconButton(tooltip: 'Remove from wishlist', onPressed: id == null ? null : () => FirestoreDatabase.instance.toggleWishlist(uid: uid, productId: id), icon: const Icon(Icons.favorite_rounded, color: coral)),
                              IconButton(tooltip: 'Add to cart', onPressed: id == null ? null : () => FirestoreDatabase.instance.addToCart(uid: uid, productId: id), icon: const Icon(Icons.shopping_bag_outlined, color: blue)),
                            ]),
                          ])),
                        ]),
                      );
                    },
                  ),
                ));
              });
            },
          );
        },
      ),
    );
  }

  static Widget _state(BuildContext context, IconData icon, String title, String subtitle, [String? action, VoidCallback? onPressed]) => Center(
    child: Padding(padding: const EdgeInsets.all(28), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 76, height: 76, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(24)), child: Icon(icon, color: blue, size: 36)),
      const SizedBox(height: 18),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(color: ink, fontSize: 21, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.5)),
      if (action != null && onPressed != null) ...[const SizedBox(height: 18), FilledButton(onPressed: onPressed, child: Text(action))],
    ]))),
  );
}
