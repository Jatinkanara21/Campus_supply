import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  static const cream = Color(0xFFFAF8F3), ink = Color(0xFF172033), blue = Color(0xFF2563EB), muted = Color(0xFF6B7280), border = Color(0xFFE7E2D9);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _auth(context);
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Your bag', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: () => Navigator.pushNamed(context, '/shop'), icon: const Icon(Icons.add_shopping_cart_rounded))]),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchCart(uid),
        builder: (context, cartSnap) {
          if (cartSnap.hasError) return _message('Unable to load your bag.');
          if (!cartSnap.hasData) return const Center(child: CircularProgressIndicator());
          final cart = cartSnap.data!;
          if (cart.isEmpty) return _empty(context);
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreDatabase.instance.watchProducts(),
            builder: (context, productSnap) {
              if (!productSnap.hasData) return const Center(child: CircularProgressIndicator());
              final byId = {for (final p in productSnap.data!) p['id'].toString(): p};
              double total = 0;
              for (final item in cart) {
                final p = byId[item['productId']?.toString()];
                total += ((p?['price'] as num?)?.toDouble() ?? 0) * ((item['quantity'] as num?)?.toInt() ?? 1);
              }
              return LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 850;
                final items = cart.map((item) => _item(context, uid, item, byId[item['productId']?.toString()])).toList();
                final summary = _summary(context, total);
                return ListView(
                  padding: EdgeInsets.fromLTRB(wide ? 34 : 18, 12, wide ? 34 : 18, 34),
                  children: [
                    Text('${cart.length} item${cart.length == 1 ? '' : 's'}', style: const TextStyle(color: muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    if (wide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(children: items)), const SizedBox(width: 22), SizedBox(width: 340, child: summary)])
                    else ...items..add(summary),
                  ],
                );
              });
            },
          );
        },
      ),
    );
  }

  Widget _item(BuildContext context, String uid, Map<String, dynamic> item, Map<String, dynamic>? p) {
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final price = (p?['price'] as num?)?.toDouble() ?? 0;
    final image = (p?['imageUrl'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      child: Row(children: [
        Container(width: 88, height: 88, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: const Color(0xFFF4F2ED), borderRadius: BorderRadius.circular(16)), child: image.isEmpty ? const Icon(Icons.inventory_2_rounded, color: blue, size: 36) : Image.network(image, fit: BoxFit.cover)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((p?['name'] ?? 'Product').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6), Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(color: blue, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(children: [
            _qtyButton(() => FirestoreDatabase.instance.updateCartQuantity(uid: uid, productId: item['productId'].toString(), quantity: qty - 1), Icons.remove_rounded),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('${qty}', style: const TextStyle(fontWeight: FontWeight.w900))),
            _qtyButton(() => FirestoreDatabase.instance.updateCartQuantity(uid: uid, productId: item['productId'].toString(), quantity: qty + 1), Icons.add_rounded),
          ]),
        ])),
      ]),
    );
  }

  Widget _qtyButton(VoidCallback onTap, IconData icon) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 17, color: blue)));

  Widget _summary(BuildContext context, double total) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Order summary', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 16),
      _row('Subtotal', '₹${total.toStringAsFixed(0)}'), _row('Delivery', 'Free'), const Divider(height: 24), _row('Total', '₹${total.toStringAsFixed(0)}', bold: true),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: () => Navigator.pushNamed(context, '/checkout', arguments: {'total': total}), child: const Text('Continue to checkout'))),
    ]),
  );

  Widget _row(String a, String b, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(a, style: TextStyle(color: muted, fontWeight: bold ? FontWeight.w800 : FontWeight.w500))), Text(b, style: TextStyle(color: ink, fontSize: bold ? 19 : 14, fontWeight: bold ? FontWeight.w900 : FontWeight.w700))]));

  Widget _empty(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 92, height: 92, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(28)), child: const Icon(Icons.shopping_bag_outlined, color: blue, size: 46)),
    const SizedBox(height: 18), const Text('Your bag is empty', style: TextStyle(color: ink, fontSize: 24, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8), const Text('Find something useful for your next class, project or creative session.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.4)),
    const SizedBox(height: 20), FilledButton(onPressed: () => Navigator.pushNamed(context, '/shop'), child: const Text('Browse shop')),
  ])));

  Widget _auth(BuildContext context) => Scaffold(backgroundColor: cream, appBar: AppBar(title: const Text('Your bag')), body: Center(child: FilledButton(onPressed: () => Navigator.pushNamed(context, '/login'), child: const Text('Sign in to view your bag'))));
  Widget _message(String text) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: muted))));
}
