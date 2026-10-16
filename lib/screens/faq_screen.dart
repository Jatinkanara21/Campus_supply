import 'package:flutter/material.dart';

import '../widgets/customer_bottom_nav.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const blue = Color(0xFF2563EB);
  static const paleBlue = Color(0xFFEAF2FF);

  @override
  Widget build(BuildContext context) {
    const faqs = [
      (
        'Can I track my order?',
        'Yes. Open My Orders from your profile to see the latest order status.',
      ),
      (
        'Do you have student bundles?',
        'Yes. Bundles group common campus essentials so you can shop faster.',
      ),
      (
        'Can I save products for later?',
        'Use the wishlist button on products to keep your favourites together.',
      ),
      (
        'How do I get support?',
        'Use the Contact page to send a message or reach the support details listed there.',
      ),
      (
        'Where can I manage my account?',
        'Open Profile for account details, orders, wishlist and settings.',
      ),
    ];

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text(
          'FAQ',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 900
              ? 28.0
              : constraints.maxWidth >= 600
                  ? 22.0
                  : 16.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _hero(),
                      const SizedBox(height: 24),
                      const Text(
                        'Common questions',
                        style: TextStyle(
                          color: ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select a question to read its answer.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ...faqs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final faq = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(color: border),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                              splashColor: paleBlue,
                              highlightColor: const Color(0x10DCE8FF),
                            ),
                            child: ExpansionTile(
                              key: PageStorageKey<String>('faq-$index'),
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 5,
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                18,
                                18,
                              ),
                              iconColor: blue,
                              collapsedIconColor: muted,
                              leading: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: paleBlue,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  (index + 1).toString().padLeft(2, '0'),
                                  style: const TextStyle(
                                    color: blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              title: Text(
                                faq.$1,
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 46),
                                    child: Text(
                                      faq.$2,
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 13,
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: paleBlue,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.support_agent_rounded,
                                color: blue,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 13),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Still need help?',
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Visit our Contact page for the listed support details.',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Open contact page',
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/contact'),
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                color: blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF2FF), Color(0xFFF5F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE7F8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'CAMPUS SUPPLY HELP',
                    style: TextStyle(
                      color: blue,
                      fontSize: 9,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Frequently asked questions',
                  style: TextStyle(
                    color: ink,
                    fontSize: 26,
                    height: 1.12,
                    letterSpacing: -.7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quick answers for shopping, bundles, saved products and your account.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: blue,
              size: 33,
            ),
          ),
        ],
      ),
    );
  }
}
