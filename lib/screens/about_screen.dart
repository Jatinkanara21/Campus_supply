import 'package:flutter/material.dart';
import '../widgets/customer_bottom_nav.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const yellow = Color(0xFFFFC66D);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('About Campus Supply', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [blue, Color(0xFF1D4ED8)]),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.auto_awesome_rounded, color: yellow, size: 30),
                      SizedBox(height: 16),
                      Text('Create more. Spend less.', style: TextStyle(color: Colors.white, fontSize: 28, height: 1.12, fontWeight: FontWeight.w900, letterSpacing: -.8)),
                      SizedBox(height: 10),
                      Text('Campus Supply is built around one idea: students should spend less time hunting for essentials and more time creating.', style: TextStyle(color: Color(0xFFEAF2FF), height: 1.55)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 700 ? 3 : 1;
                    final cards = [
                      _card(Icons.school_rounded, 'Built for campus life', 'From pens and notebooks to drafting and creative tools, the experience is designed around student routines.'),
                      _card(Icons.widgets_outlined, 'Curated, not complicated', 'Clear categories, useful bundles and a focused shopping flow keep the catalog easy to explore.'),
                      _card(Icons.favorite_border_rounded, 'Student-first value', 'The brand focuses on practical essentials, smart bundles and simple experiences.'),
                    ];
                    if (columns == 1) return Column(children: cards);
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 14),
                        Expanded(child: cards[i]),
                      ],
                    ]);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }

  static Widget _card(IconData icon, String title, String text) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: blue)),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(text, style: const TextStyle(color: muted, height: 1.5)),
        ]),
      );
}
