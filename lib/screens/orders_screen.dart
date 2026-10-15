import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/customer_bottom_nav.dart';

import '../database/firestore_database.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const green = Color(0xFF15803D);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const softBlue = Color(0xFFEAF2FF);
  static const amber = Color(0xFF9A6700);
  static const red = Color(0xFFB42318);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _auth(context);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('My orders', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Shop',
            onPressed: () => Navigator.pushNamed(context, '/shop'),
            icon: const Icon(Icons.add_shopping_cart_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchOrders(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _state(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load orders',
              subtitle: 'Please try again in a moment.',
            );
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return _state(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Your purchases will appear here after you place an order.',
              action: 'Start shopping',
              onPressed: () => Navigator.pushNamed(context, '/shop'),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth >= 900 ? 30.0 : 16.0;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, 36),
                    children: [
                      _pageIntro(orders.length),
                      const SizedBox(height: 22),
                      ...orders.map((order) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _orderCard(order),
                      )),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }

  Widget _pageIntro(int orderCount) {
    final orderWord = orderCount == 1 ? 'order' : 'orders';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your order history',
                style: TextStyle(
                  color: ink,
                  fontSize: 27,
                  height: 1.14,
                  letterSpacing: -0.7,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'View the status and total for your purchases.',
                style: TextStyle(color: muted, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(14)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                orderCount.toString(),
                style: const TextStyle(color: blue, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              Text(
                orderWord.toUpperCase(),
                style: const TextStyle(color: muted, fontSize: 8, letterSpacing: .7, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final id = (order['id'] ?? '').toString();
    final status = (order['status'] ?? 'pending').toString();
    final normalizedStatus = status.toLowerCase().trim();
    final statusColor = _statusColor(normalizedStatus);
    final rawTotal = order['total'];
    final total = rawTotal is num
        ? rawTotal.toDouble()
        : double.tryParse((rawTotal ?? '').toString()) ?? 0;
    final items = order['items'] as List?;
    final itemCount = items?.fold<int>(0, (sum, entry) {
          if (entry is Map) {
            final quantity = entry['quantity'];
            if (quantity is num) {
              final safeQuantity = quantity.toInt();
              return sum + (safeQuantity < 0 ? 0 : safeQuantity);
            }
          }
          return sum + 1;
        }) ??
        0;
    final progress = _statusProgress(normalizedStatus);
    final cancelled = normalizedStatus == 'cancelled';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(color: Color(0x07172554), blurRadius: 18, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.receipt_long_rounded, color: blue, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ORDER ID',
                        style: TextStyle(color: muted, fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        id.isEmpty ? 'Order ID unavailable' : '#' + id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(status, statusColor),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 17),
            child: Divider(height: 1),
          ),
          Wrap(
            spacing: 28,
            runSpacing: 14,
            children: [
              _orderMetric(
                label: 'ORDER TOTAL',
                value: '₹' + total.toStringAsFixed(0),
                icon: Icons.currency_rupee_rounded,
                prominent: true,
              ),
              _orderMetric(
                label: 'ITEMS',
                value: itemCount.toString(),
                icon: Icons.shopping_bag_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (cancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(color: const Color(0xFFFFE9E6), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined, color: red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This order is marked as ' + _displayStatus(status) + '.',
                      style: const TextStyle(color: red, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          else if (progress != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ORDER STATUS',
                        style: TextStyle(color: muted, fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      _displayStatus(status),
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: softBlue,
                    color: statusColor,
                  ),
                ),
              ],
            )
          else
            Text(
              'Current status: ' + status,
              style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Text(
        status.isEmpty ? 'UNKNOWN' : status.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 9, letterSpacing: .35, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _orderMetric({
    required String label,
    required String value,
    required IconData icon,
    bool prominent = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: prominent ? const Color(0xFFFFF4D5) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 17, color: prominent ? const Color(0xFF946200) : muted),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: muted, fontSize: 9, letterSpacing: .7, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: prominent ? blue : ink,
                fontSize: prominent ? 22 : 17,
                fontWeight: FontWeight.w900,
                letterSpacing: prominent ? -0.5 : 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return amber;
      case 'confirmed':
        return blue;
      case 'shipped':
        return const Color(0xFF4F46E5);
      case 'delivered':
        return green;
      case 'cancelled':
        return red;
      default:
        return muted;
    }
  }

  static double? _statusProgress(String status) {
    switch (status) {
      case 'pending':
        return 0.2;
      case 'confirmed':
        return 0.45;
      case 'shipped':
        return 0.75;
      case 'delivered':
        return 1;
      default:
        return null;
    }
  }

  static String _displayStatus(String status) {
    final value = status.trim();
    if (value.isEmpty) return 'Unknown';
    return value[0].toUpperCase() + value.substring(1);
  }

  Widget _auth(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Orders')),
      body: _state(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to view orders',
        subtitle: 'Your order history is available after you sign in.',
        action: 'Sign in',
        onPressed: () => Navigator.pushNamed(context, '/login'),
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }

  Widget _state({
    required IconData icon,
    required String title,
    required String subtitle,
    String? action,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(26)),
                child: Icon(icon, color: blue, size: 39),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ink, fontSize: 23, letterSpacing: -0.4, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, height: 1.55, fontSize: 13),
              ),
              if (action != null && onPressed != null) ...[
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: Text(action),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
