import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../database/firestore_database.dart';
import '../widgets/app_image.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const softBlue = Color(0xFFEAF2FF);
  static const danger = Color(0xFFB42318);
  static const softRed = Color(0xFFFFE9E6);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _auth(context);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Your bag', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Continue shopping',
            onPressed: () => Navigator.pushNamed(context, '/shop'),
            icon: const Icon(Icons.add_shopping_cart_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchCart(uid),
        builder: (context, cartSnap) {
          if (cartSnap.hasError) {
            return _state(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load your bag',
              subtitle: 'Please check your connection and try again.',
              actionLabel: 'Browse shop',
              onAction: () => Navigator.pushNamed(context, '/shop'),
            );
          }
          if (!cartSnap.hasData) return const Center(child: CircularProgressIndicator());
          final cart = cartSnap.data!;
          if (cart.isEmpty) return _empty(context);

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreDatabase.instance.watchProducts(),
            builder: (context, productSnap) {
              if (productSnap.hasError) {
                return _state(
                  icon: Icons.inventory_2_outlined,
                  title: 'Product details unavailable',
                  subtitle: 'We could not load product prices right now. Please try again shortly.',
                );
              }
              if (!productSnap.hasData) return const Center(child: CircularProgressIndicator());

              final byId = {
                for (final product in productSnap.data!)
                  product['id'].toString(): product,
              };
              double total = 0;
              var totalUnits = 0;
              for (final item in cart) {
                final product = byId[item['productId']?.toString()];
                final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                total += ((product?['price'] as num?)?.toDouble() ?? 0) * qty;
                totalUnits += qty;
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 850;
                  final items = cart.map((item) => _item(
                    context,
                    uid,
                    item,
                    byId[item['productId']?.toString()],
                  )).toList();
                  final summary = _summary(context, total, cart.length);
                  final sections = wide
                      ? <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Column(children: items)),
                              const SizedBox(width: 22),
                              SizedBox(width: 330, child: summary),
                            ],
                          ),
                        ]
                      : <Widget>[...items, const SizedBox(height: 6), summary];

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(wide ? 30 : 16, 20, wide ? 30 : 16, 36),
                        children: [
                          _heading(totalUnits, cart.length),
                          const SizedBox(height: 22),
                          ...sections,
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _heading(int totalUnits, int productCount) {
    final itemWord = totalUnits == 1 ? 'item' : 'items';
    final productWord = productCount == 1 ? 'product' : 'products';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review your essentials',
          style: TextStyle(color: ink, fontSize: 24, height: 1.15, letterSpacing: -0.6, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          '$totalUnits $itemWord across $productCount $productWord',
          style: const TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _item(BuildContext context, String uid, Map<String, dynamic> item, Map<String, dynamic>? product) {
    final id = item['productId']?.toString() ?? '';
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final rawPrice = product?['price'];
    final price = rawPrice is num ? rawPrice.toDouble() : double.tryParse((rawPrice ?? '').toString());
    final storedImage = (product?['imageUrl'] ?? '').toString().trim();
    final image = storedImage.isNotEmpty ? storedImage : _fallbackImagePath(product);
    final name = (product?['name'] ?? '').toString().trim();
    final category = (product?['category'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: const [BoxShadow(color: Color(0x07172554), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 108,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: const Color(0xFFF3F6FB), borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AppImage(
                source: image,
                fit: BoxFit.contain,
                fallback: const Center(child: Icon(Icons.inventory_2_outlined, color: blue, size: 36)),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name.isEmpty ? 'Product unavailable' : name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: ink, fontSize: 14, height: 1.3, fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove item',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      padding: EdgeInsets.zero,
                      onPressed: id.isEmpty ? null : () => _confirmRemove(
                        context,
                        uid: uid,
                        productId: id,
                        productName: name.isEmpty ? 'this item' : name,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: danger,
                        backgroundColor: softRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    ),
                  ],
                ),
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(category, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 7),
                Text(
                  price == null ? 'Price unavailable' : '₹' + price.toStringAsFixed(0),
                  style: TextStyle(color: price == null ? muted : blue, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 5,
                  children: [
                    _qtyButton(
                      tooltip: 'Decrease quantity',
                      icon: Icons.remove_rounded,
                      onTap: id.isEmpty ? null : () => _updateQuantity(context, uid, id, qty - 1),
                    ),
                    SizedBox(
                      width: 24,
                      child: Text(qty.toString(), textAlign: TextAlign.center,
                        style: const TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w900)),
                    ),
                    _qtyButton(
                      tooltip: 'Increase quantity',
                      icon: Icons.add_rounded,
                      onTap: id.isEmpty ? null : () => _updateQuantity(context, uid, id, qty + 1),
                    ),
                    if (price != null)
                      Text('Line total ₹' + (price * qty).toStringAsFixed(0),
                        style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fallbackImagePath(Map<String, dynamic>? product) {
    final value = ((product?['name'] ?? '').toString() + ' ' + (product?['category'] ?? '').toString()).toLowerCase();
    if (value.contains('backpack') || value.contains('bag')) return 'assets/image/products/backpack.svg';
    if (value.contains('headphone')) return 'assets/image/products/headphones.svg';
    if (value.contains('bottle') || value.contains('tumbler')) return 'assets/image/products/bottle.svg';
    if (value.contains('calculator')) return 'assets/image/products/calculator.svg';
    if (value.contains('lamp')) return 'assets/image/products/lamp.svg';
    if (value.contains('sleeve')) return 'assets/image/products/sleeve.svg';
    if (value.contains('pen')) return 'assets/image/products/pen.svg';
    if (value.contains('notebook') || value.contains('stationery')) return 'assets/image/products/notebook.svg';
    return '';
  }

  Widget _qtyButton({required String tooltip, required IconData icon, required VoidCallback? onTap}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: onTap == null ? const Color(0xFFF1F5F9) : softBlue,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: onTap == null ? border : const Color(0xFFD9E6FF)),
          ),
          child: Icon(icon, size: 17, color: onTap == null ? muted : blue),
        ),
      ),
    );
  }

  Future<void> _updateQuantity(BuildContext context, String uid, String id, int qty) async {
    try {
      await FirestoreDatabase.instance.updateCartQuantity(uid: uid, productId: id, quantity: qty);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update quantity. Please try again.')),
        );
      }
    }
  }

  Future<void> _confirmRemove(
    BuildContext context, {
    required String uid,
    required String productId,
    required String productName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove ' + productName + ' from your bag?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep item')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await FirestoreDatabase.instance.removeFromCart(uid: uid, productId: productId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item removed from your bag.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove the item. Please try again.')),
        );
      }
    }
  }

  Widget _summary(BuildContext context, double total, int productCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: const [BoxShadow(color: Color(0x08172554), blurRadius: 20, offset: Offset(0, 7))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.receipt_long_rounded, color: blue, size: 21),
            ),
            const SizedBox(width: 11),
            const Expanded(child: Text('Order summary',
              style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 19),
          _summaryRow('Subtotal', '₹' + total.toStringAsFixed(0)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1)),
          Row(children: [
            const Expanded(child: Text('Total',
              style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w900))),
            Text('₹' + total.toStringAsFixed(0),
              style: const TextStyle(color: blue, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -0.6)),
          ]),
          const SizedBox(height: 8),
          Text(
            'Based on $productCount ' + (productCount == 1 ? 'product' : 'products') + ' in your bag.',
            style: const TextStyle(color: muted, fontSize: 11, height: 1.45),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(13)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: ink, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Your total updates when you change item quantities.',
                  style: TextStyle(color: ink, fontSize: 11, height: 1.45, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/checkout', arguments: {'total': total}),
              icon: const Icon(Icons.lock_outline_rounded, size: 18),
              label: const Text('Continue to checkout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Row(children: [
    Expanded(child: Text(label, style: const TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600))),
    Text(value, style: const TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w800)),
  ]);

  Widget _empty(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(30)),
            child: const Icon(Icons.shopping_bag_outlined, color: blue, size: 46),
          ),
          const SizedBox(height: 20),
          const Text('Your bag is empty', textAlign: TextAlign.center,
            style: TextStyle(color: ink, fontSize: 25, letterSpacing: -0.5, fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          const Text('Find something useful for your next class, project or creative session.',
            textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.55)),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/shop'),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Browse shop'),
          ),
        ]),
      ),
    ),
  );

  Widget _auth(BuildContext context) => Scaffold(
    backgroundColor: cream,
    appBar: AppBar(title: const Text('Your bag')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.lock_outline_rounded, color: blue, size: 36),
            ),
            const SizedBox(height: 18),
            const Text('Sign in to view your bag', textAlign: TextAlign.center,
              style: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            const Text('Your cart items are linked to your account.',
              textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.pushNamed(context, '/login'), child: const Text('Sign in')),
            ),
          ]),
        ),
      ),
    ),
  );

  Widget _state({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(24)),
            child: Icon(icon, color: blue, size: 36),
          ),
          const SizedBox(height: 18),
          Text(title, textAlign: TextAlign.center,
            style: const TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.5)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ]),
      ),
    ),
  );
}
