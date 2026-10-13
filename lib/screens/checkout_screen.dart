import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();
  final pin = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    city.dispose();
    pin.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(double total, List<Map<String, dynamic>> cart, Map<String, Map<String, dynamic>> byId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) Navigator.pushNamed(context, '/login');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your bag is empty. Add an item before checkout.')));
      return;
    }

    setState(() => loading = true);
    var orderCreated = false;
    final items = cart.map((item) {
      final product = byId[item['productId']?.toString()];
      return {
        'productId': item['productId'],
        'name': product?['name'] ?? 'Product',
        'price': product?['price'] ?? 0,
        'quantity': item['quantity'] ?? 1,
      };
    }).toList();

    try {
      await FirestoreDatabase.instance.createOrder(uid: uid, items: items, total: total, status: 'pending');
      orderCreated = true;
      try {
        await FirestoreDatabase.instance.clearCart(uid);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Your order was placed, but the bag could not be cleared. Please review it before ordering again.'),
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pushNamedAndRemoveUntil(context, '/orders', (_) => false);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully.'), behavior: SnackBarBehavior.floating));
      Navigator.pushNamedAndRemoveUntil(context, '/orders', (_) => false);
    } catch (_) {
      if (!mounted) return;
      final message = orderCreated
          ? 'Your order was placed, but checkout needs attention. Please check My Orders.'
          : 'We could not place your order. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Scaffold(backgroundColor: cream, appBar: AppBar(title: const Text('Checkout')), body: Center(child: FilledButton(onPressed: () => Navigator.pushNamed(context, '/login'), child: const Text('Sign in to checkout'))));

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w900))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchCart(uid),
        builder: (context, cartSnap) {
          if (cartSnap.hasError) return _state('Unable to load your bag. Please try again.');
          if (!cartSnap.hasData) return const Center(child: CircularProgressIndicator());
          final cart = cartSnap.data!;
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreDatabase.instance.watchProducts(),
            builder: (context, productSnap) {
              if (productSnap.hasError) return _state('Unable to load product details. Please try again.');
              if (!productSnap.hasData) return const Center(child: CircularProgressIndicator());
              final byId = {for (final p in productSnap.data!) p['id'].toString(): p};
              double total = 0;
              for (final item in cart) {
                final product = byId[item['productId']?.toString()];
                total += ((product?['price'] as num?)?.toDouble() ?? 0) * ((item['quantity'] as num?)?.toInt() ?? 1);
              }
              return LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final details = _section('Delivery details', [
                  TextFormField(controller: name, textInputAction: TextInputAction.next, decoration: _decoration('Full name', Icons.person_outline_rounded), validator: (v) => v == null || v.trim().isEmpty ? 'Enter your full name.' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: phone, keyboardType: TextInputType.phone, maxLength: 10, textInputAction: TextInputAction.next, decoration: _decoration('Phone number', Icons.phone_outlined), validator: (v) => RegExp(r'^[0-9]{10}$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid 10-digit Indian mobile number.'),
                  const SizedBox(height: 2),
                  TextFormField(controller: address, textInputAction: TextInputAction.next, decoration: _decoration('Delivery address', Icons.location_on_outlined, alignLabelWithHint: true), maxLines: 3, validator: (v) => v == null || v.trim().isEmpty ? 'Enter your delivery address.' : null),
                  const SizedBox(height: 12),
                  if (constraints.maxWidth >= 520)
                    Row(children: [
                      Expanded(child: TextFormField(controller: city, textInputAction: TextInputAction.next, decoration: _decoration('City', Icons.location_city_outlined), validator: (v) => v == null || v.trim().isEmpty ? 'Enter your city.' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: pin, keyboardType: TextInputType.number, maxLength: 6, decoration: _decoration('PIN code', Icons.markunread_mailbox_outlined), validator: (v) => RegExp(r'^[0-9]{6}$').hasMatch((v ?? '').trim()) ? null : 'Enter a 6-digit PIN code.')),
                    ])
                  else ...[
                    TextFormField(controller: city, textInputAction: TextInputAction.next, decoration: _decoration('City', Icons.location_city_outlined), validator: (v) => v == null || v.trim().isEmpty ? 'Enter your city.' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: pin, keyboardType: TextInputType.number, maxLength: 6, decoration: _decoration('PIN code', Icons.markunread_mailbox_outlined), validator: (v) => RegExp(r'^[0-9]{6}$').hasMatch((v ?? '').trim()) ? null : 'Enter a 6-digit PIN code.'),
                  ],
                ]);
                final summary = _section('Order summary', [
                  _row('Items', '${cart.length}'),
                  _row('Delivery', 'Free'),
                  const Divider(height: 24),
                  _row('Total', '₹${total.toStringAsFixed(0)}', bold: true),
                ]);
                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                    children: [
                      Center(child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: wide
                            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Expanded(flex: 7, child: details),
                                const SizedBox(width: 18),
                                Expanded(flex: 4, child: Column(children: [
                                  summary,
                                  const SizedBox(height: 14),
                                  _placeButton(total, cart, byId),
                                ])),
                              ])
                            : Column(children: [
                                details,
                                const SizedBox(height: 14),
                                summary,
                                const SizedBox(height: 14),
                                _placeButton(total, cart, byId),
                              ]),
                      )),
                    ],
                  ),
                );
              });
            },
          );
        },
      ),
    );
  }

  Widget _placeButton(double total, List<Map<String, dynamic>> cart, Map<String, Map<String, dynamic>> byId) => SizedBox(
    width: double.infinity,
    height: 54,
    child: FilledButton.icon(
      onPressed: loading ? null : () => _placeOrder(total, cart, byId),
      icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline_rounded),
      label: Text(loading ? 'Placing order…' : 'Place order', style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
  );

  Widget _section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      ...children,
    ]),
  );

  InputDecoration _decoration(String label, IconData icon, {bool alignLabelWithHint = false}) => InputDecoration(
    labelText: label,
    prefixIcon: alignLabelWithHint ? null : Icon(icon, size: 20),
    alignLabelWithHint: alignLabelWithHint,
    filled: true,
    fillColor: const Color(0xFFFAF8F3),
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: blue, width: 1.5)),
  );

  Widget _row(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: muted))),
      Text(value, style: TextStyle(color: ink, fontWeight: bold ? FontWeight.w900 : FontWeight.w700, fontSize: bold ? 20 : 14)),
    ]),
  );

  Widget _state(String message) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: muted))));
}
