import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  static const cream = Color(0xFFFAF8F3), ink = Color(0xFF172554), blue = Color(0xFF2563EB), green = Color(0xFF15803D), muted = Color(0xFF64748B), border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Scaffold(backgroundColor: cream, appBar: AppBar(title: const Text('Orders')), body: _state(Icons.lock_outline_rounded, 'Sign in to view orders', 'Your order history is available after you sign in.', 'Sign in', () => Navigator.pushNamed(context, '/login')));
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('My orders', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(tooltip: 'Shop', onPressed: () => Navigator.pushNamed(context, '/shop'), icon: const Icon(Icons.add_shopping_cart_rounded))]),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchOrders(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _state(Icons.cloud_off_outlined, 'Unable to load orders', 'Please try again in a moment.');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data!;
          if (orders.isEmpty) return _state(Icons.receipt_long_outlined, 'No orders yet', 'Your purchases will appear here.', 'Start shopping', () => Navigator.pushNamed(context, '/shop'));
          return Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final order = orders[i];
                final status = (order['status'] ?? 'pending').toString();
                final delivered = status.toLowerCase() == 'delivered';
                final color = delivered ? green : blue;
                final total = ((order['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
                final itemCount = (order['items'] as List?)?.length ?? 0;
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.receipt_long_rounded, color: blue, size: 20)),
                      const SizedBox(width: 10),
                      Expanded(child: Text('#${order['id']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontWeight: FontWeight.w900))),
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(10)), child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900))),
                    ]),
                    const SizedBox(height: 15),
                    Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 8, children: [
                      Text('₹$total', style: const TextStyle(color: blue, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text('$itemCount item line(s)', style: const TextStyle(color: muted, fontSize: 13)),
                    ]),
                    const SizedBox(height: 15),
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: delivered ? 1 : .5, minHeight: 7, backgroundColor: const Color(0xFFEAF2FF), color: color)),
                  ]),
                );
              },
            ),
          ));
        },
      ),
    );
  }

  static Widget _state(IconData icon, String title, String subtitle, [String? action, VoidCallback? onPressed]) => Center(
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
