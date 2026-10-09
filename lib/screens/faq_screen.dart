import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const cream = Color(0xFFF5F7FB);
  static const ink = Color(0xFF172554);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    const faqs = [
      ('Can I track my order?', 'Yes. Open My Orders from your profile to see the latest order status.'),
      ('Do you have student bundles?', 'Yes. Bundles group common campus essentials so you can shop faster.'),
      ('Can I save products for later?', 'Use the wishlist button on products to keep your favourites together.'),
      ('How do I get support?', 'Use the Contact page to send a message or reach the support details listed there.'),
      ('Where can I manage my account?', 'Open Profile for account details, orders, wishlist and settings.'),
    ];

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('FAQ', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          const Text('Frequently asked questions', style: TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -.8)),
          const SizedBox(height: 7),
          const Text('Quick answers for the things students ask most.', style: TextStyle(color: muted)),
          const SizedBox(height: 16),
          ...faqs.map((faq) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
                child: ExpansionTile(
                  title: Text(faq.$1, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [Text(faq.$2, style: const TextStyle(color: muted, height: 1.45))],
                ),
              )),
        ],
      ),
    );
  }
}
