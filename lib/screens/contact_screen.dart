import 'package:flutter/material.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172033);
  static const blue = Color(0xFF2563EB);
  static const muted = Color(0xFF707681);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Contact', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          const Text('Need a hand?', style: TextStyle(color: ink, fontSize: 29, fontWeight: FontWeight.w900, letterSpacing: -.8)),
          const SizedBox(height: 7),
          const Text('Questions about products, orders or student savings? Send us a message.', style: TextStyle(color: muted, height: 1.4)),
          const SizedBox(height: 18),
          _tile(Icons.mail_outline_rounded, 'Email', 'hello@campussupply.example'),
          _tile(Icons.support_agent_rounded, 'Support', 'Mon–Sat • 10:00 AM–7:00 PM'),
          _tile(Icons.location_on_outlined, 'Campus desk', 'Ahmedabad, Gujarat'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE7E2D9))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Send an enquiry', style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              const TextField(decoration: InputDecoration(labelText: 'Email')),
              const SizedBox(height: 10),
              const TextField(decoration: InputDecoration(labelText: 'Message'), maxLines: 4),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: () {}, child: const Text('Send message'))),
            ]),
          ),
        ],
      ),
    );
  }

  static Widget _tile(IconData icon, String title, String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE7E2D9))),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: blue)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(text, style: const TextStyle(color: muted, fontSize: 12))])),
        ]),
      );
}
