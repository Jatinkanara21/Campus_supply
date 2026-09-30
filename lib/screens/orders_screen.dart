import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172033);
  static const blue = Color(0xFF2563EB);
  static const green = Color(0xFF198754);
  static const muted = Color(0xFF707681);

  @override
  Widget build(BuildContext context) {
    final orders = [
      ('#CS-1042', 'Campus essentials', '₹1,046', 'Delivered', green),
      ('#CS-1037', 'Design student kit', '₹1,499', 'Shipped', blue),
      ('#CS-1029', 'Exam Survival Kit', '₹699', 'Processing', const Color(0xFFF4B400)),
    ];

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final o = orders[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE7E2D9))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(o.$1, style: const TextStyle(color: ink, fontWeight: FontWeight.w900))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: o.$5.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
                    child: Text(o.$4, style: TextStyle(color: o.$5, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(o.$2, style: const TextStyle(color: muted)),
                const SizedBox(height: 5),
                Text(o.$3, style: const TextStyle(color: blue, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: green, size: 18),
                    SizedBox(width: 7),
                    Text('View order details', style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
                    Spacer(),
                    Icon(Icons.chevron_right_rounded, color: muted),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
