import 'package:flutter/material.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172033);
  static const blue = Color(0xFF2563EB);
  static const yellow = Color(0xFFFACC15);
  static const muted = Color(0xFF707681);
  static const border = Color(0xFFE7E2D9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w900))),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final form = ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
            children: [
              _section('Delivery details', [
                const TextField(decoration: InputDecoration(labelText: 'Full name', hintText: 'Your name')),
                const SizedBox(height: 12),
                const TextField(decoration: InputDecoration(labelText: 'Phone number', hintText: '+91')),
                const SizedBox(height: 12),
                const TextField(decoration: InputDecoration(labelText: 'Address', hintText: 'Street, building, area'), maxLines: 3),
                const SizedBox(height: 12),
                const Row(children: [
                  Expanded(child: TextField(decoration: InputDecoration(labelText: 'City'))),
                  SizedBox(width: 10),
                  Expanded(child: TextField(decoration: InputDecoration(labelText: 'PIN code'))),
                ]),
              ]),
              const SizedBox(height: 14),
              _section('Payment method', [
                RadioListTile<String>(
                  value: 'cod',
                  groupValue: 'cod',
                  onChanged: (_) {},
                  title: const Text('Cash on delivery'),
                  subtitle: const Text('Pay when your order arrives.'),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'online',
                  groupValue: 'cod',
                  onChanged: (_) {},
                  title: const Text('Online payment'),
                  subtitle: const Text('Secure payment gateway placeholder.'),
                  contentPadding: EdgeInsets.zero,
                ),
              ]),
              const SizedBox(height: 14),
              _section('Order review', [
                _row('Campus essentials', '₹1,046'),
                _row('Delivery', 'Free'),
                const Divider(height: 22),
                _row('Total', '₹1,046', bold: true),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/orders', (_) => false);
                  },
                  child: const Text('Place order'),
                ),
              ),
            ],
          );

          if (!wide) return form;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: form),
              SizedBox(
                width: 330,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 18, 30),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: border)),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order summary', style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w900)),
                        SizedBox(height: 14),
                        Text('3 items', style: TextStyle(color: muted)),
                        SizedBox(height: 8),
                        Text('Total  ₹1,046', style: TextStyle(color: blue, fontSize: 22, fontWeight: FontWeight.w900)),
                        SizedBox(height: 8),
                        Text('Free delivery included.', style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _section(String title, List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...children,
        ]),
      );

  static Widget _row(String a, String b, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(a, style: const TextStyle(color: muted))),
          Text(b, style: TextStyle(color: ink, fontWeight: bold ? FontWeight.w900 : FontWeight.w700, fontSize: bold ? 18 : 14)),
        ]),
      );
}
