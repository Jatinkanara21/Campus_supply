import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const cream = Color(0xFFF5F7FB);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF3157D5);
  static const yellow = Color(0xFFFFC66D);
  static const muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('About Campus Supply', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(28)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.auto_awesome_rounded, color: yellow, size: 28),
              SizedBox(height: 14),
              Text('Create more. Spend less.', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -1)),
              SizedBox(height: 8),
              Text('Campus Supply is built around one idea: students should spend less time hunting for essentials and more time creating.', style: TextStyle(color: Color(0xFFE8EEFF), height: 1.45)),
            ]),
          ),
          const SizedBox(height: 18),
          _card('Built for campus life', 'From pens and notebooks to drafting and creative tools, the experience is designed around student routines.'),
          _card('Curated, not complicated', 'Clear categories, useful bundles and a focused shopping flow keep the catalog easy to explore.'),
          _card('Student-first value', 'The brand focuses on practical essentials, smart bundles and simple experiences.'),
        ],
      ),
    );
  }

  static Widget _card(String title, String text) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(text, style: const TextStyle(color: muted, height: 1.45)),
        ]),
      );
}
