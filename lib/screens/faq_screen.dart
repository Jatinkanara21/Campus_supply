import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const blue = Color(0xFF2563EB);

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
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Frequently asked questions', style: TextStyle(color: ink, fontSize: 28, height: 1.12, fontWeight: FontWeight.w900, letterSpacing: -.8)),
                const SizedBox(height: 8),
                const Text('Quick answers for the things students ask most.', style: TextStyle(color: muted, height: 1.45)),
                const SizedBox(height: 20),
                ...faqs.map((faq) => Container(
                  margin: const EdgeInsets.only(bottom: 11),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent, splashColor: const Color(0xFFEAF2FF)),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      iconColor: blue,
                      collapsedIconColor: muted,
                      title: Text(faq.$1, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
                      children: [Align(alignment: Alignment.centerLeft, child: Text(faq.$2, style: const TextStyle(color: muted, height: 1.55)))],
                    ),
                  ),
                )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
