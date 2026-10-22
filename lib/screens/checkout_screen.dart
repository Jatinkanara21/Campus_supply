import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/customer_bottom_nav.dart';

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
  static const softBlue = Color(0xFFEAF2FF);
  static const yellow = Color(0xFFFFC66D);

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

  Future<void> _placeOrder(
    double total,
    List<Map<String, dynamic>> cart,
    Map<String, Map<String, dynamic>> byId,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) Navigator.pushNamed(context, '/login');
      return;
    }
    if (loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your bag is empty. Add an item before checkout.'),
        ),
      );
      return;
    }

    setState(() => loading = true);
    var orderCreated = false;
    final items = cart.map((item) {
      final isBundle = (item['itemType'] ?? 'product').toString() == 'bundle';
      if (isBundle) {
        return <String, dynamic>{
          'itemType': 'bundle',
          'bundleId': item['bundleId'],
          'name': item['bundleName'] ?? 'Student Bundle',
          'price': item['bundlePrice'] ?? 0,
          'imageUrl': item['bundleImageUrl'] ?? '',
          'quantity': item['quantity'] ?? 1,
          'includedProductIds': item['includedProductIds'] is List ? item['includedProductIds'] : <dynamic>[],
          'includedItems': item['includedItems'] is List ? item['includedItems'] : <dynamic>[],
        };
      }
      final product = byId[item['productId']?.toString()];
      return <String, dynamic>{
        'itemType': 'product',
        'productId': item['productId'],
        'name': product?['name'] ?? 'Product',
        'price': product?['price'] ?? 0,
        'quantity': item['quantity'] ?? 1,
      };
    }).toList();

    try {
      await FirestoreDatabase.instance.createOrder(
        uid: uid,
        items: items,
        total: total,
        status: 'pending',
        customerName: name.text.trim(),
        customerPhone: phone.text.trim(),
        customerEmail: FirebaseAuth.instance.currentUser?.email?.trim() ?? '',
        deliveryAddress: address.text.trim(),
        deliveryCity: city.text.trim(),
        deliveryPinCode: pin.text.trim(),
      );
      orderCreated = true;

      try {
        await FirestoreDatabase.instance.clearCart(uid);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your order was placed, but the bag could not be cleared. '
              'Please review it before ordering again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/orders', (_) => false);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/orders', (_) => false);
    } catch (_) {
      if (!mounted) return;
      final message = orderCreated
          ? 'Your order was placed, but checkout needs attention. Please check My Orders.'
          : 'We could not place your order. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _auth(context);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchCart(uid),
        builder: (context, cartSnap) {
          if (cartSnap.hasError) {
            return _state(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load your bag',
              message: 'Please check your connection and try again.',
              actionLabel: 'Browse shop',
              onAction: () => Navigator.pushNamed(context, '/shop'),
            );
          }
          if (!cartSnap.hasData) return const Center(child: CircularProgressIndicator());

          final cart = cartSnap.data!;
          if (cart.isEmpty) return _emptyCart(context);

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreDatabase.instance.watchProducts(),
            builder: (context, productSnap) {
              if (productSnap.hasError) {
                return _state(
                  icon: Icons.inventory_2_outlined,
                  title: 'Product details unavailable',
                  message: 'We could not load product prices. Please try again shortly.',
                );
              }
              if (!productSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final byId = {
                for (final product in productSnap.data!)
                  product['id'].toString(): product,
              };

              // Product lines use catalog prices; bundle lines use their own package price.
              double total = 0;
              var totalUnits = 0;
              for (final item in cart) {
                final isBundle = (item['itemType'] ?? 'product').toString() == 'bundle';
                final product = isBundle ? null : byId[item['productId']?.toString()];
                final rawPrice = isBundle ? item['bundlePrice'] : product?['price'];
                final price = rawPrice is num ? rawPrice.toDouble() : double.tryParse((rawPrice ?? '').toString()) ?? 0;
                final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                total += price * quantity;
                totalUnits += quantity;
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  final details = _deliverySection(constraints.maxWidth);
                  final summary = _orderSummary(
                    total: total,
                    totalUnits: totalUnits,
                    productCount: cart.length,
                  );

                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        constraints.maxWidth >= 900 ? 28 : 16,
                        18,
                        constraints.maxWidth >= 900 ? 28 : 16,
                        32,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1120),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _pageIntro(totalUnits),
                                const SizedBox(height: 22),
                                if (wide)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 7, child: details),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          children: [
                                            summary,
                                            const SizedBox(height: 14),
                                            _placeButton(total, cart, byId),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  details,
                                  const SizedBox(height: 16),
                                  summary,
                                  const SizedBox(height: 14),
                                  _placeButton(total, cart, byId),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }

  Widget _pageIntro(int totalUnits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Almost there.',
          style: TextStyle(
            color: ink,
            fontSize: 28,
            height: 1.12,
            letterSpacing: -0.8,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Complete your delivery details to place your order. '
          + totalUnits.toString()
          + (totalUnits == 1 ? ' item in your bag.' : ' items in your bag.'),
          style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _deliverySection(double width) {
    return _section(
      icon: Icons.local_shipping_outlined,
      title: 'Delivery details',
      subtitle: 'Fields marked with * are required.',
      children: [
        _input(
          controller: name,
          label: 'Full name',
          icon: Icons.person_outline_rounded,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter your full name.' : null,
        ),
        const SizedBox(height: 14),
        _input(
          controller: phone,
          label: 'Phone number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          validator: (value) => RegExp(r'^[0-9]{10}$').hasMatch((value ?? '').trim())
              ? null
              : 'Enter a valid 10-digit Indian mobile number.',
        ),
        const SizedBox(height: 14),
        _input(
          controller: address,
          label: 'Delivery address',
          icon: Icons.location_on_outlined,
          alignLabelWithHint: true,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter your delivery address.' : null,
        ),
        const SizedBox(height: 14),
        if (width >= 560)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _input(
                  controller: city,
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Enter your city.' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _input(
                  controller: pin,
                  label: 'PIN code',
                  icon: Icons.markunread_mailbox_outlined,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textInputAction: TextInputAction.done,
                  validator: (value) => RegExp(r'^[0-9]{6}$').hasMatch((value ?? '').trim())
                      ? null
                      : 'Enter a 6-digit PIN code.',
                ),
              ),
            ],
          )
        else ...[
          _input(
            controller: city,
            label: 'City',
            icon: Icons.location_city_outlined,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter your city.' : null,
          ),
          const SizedBox(height: 14),
          _input(
            controller: pin,
            label: 'PIN code',
            icon: Icons.markunread_mailbox_outlined,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            validator: (value) => RegExp(r'^[0-9]{6}$').hasMatch((value ?? '').trim())
                ? null
                : 'Enter a 6-digit PIN code.',
          ),
        ],
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    int? maxLength,
    int maxLines = 1,
    bool alignLabelWithHint = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      decoration: _decoration(
        label + ' *',
        icon,
        alignLabelWithHint: alignLabelWithHint,
      ),
    );
  }

  Widget _orderSummary({
    required double total,
    required int totalUnits,
    required int productCount,
  }) {
    return _section(
      icon: Icons.receipt_long_rounded,
      title: 'Order summary',
      subtitle: 'Review the total calculated from your bag.',
      children: [
        _summaryRow('Items', totalUnits.toString()),
        const SizedBox(height: 10),
        _summaryRow('Products', productCount.toString()),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(height: 1),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text(
                'Total',
                style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '₹' + total.toStringAsFixed(0),
              style: const TextStyle(
                color: blue,
                fontSize: 27,
                letterSpacing: -0.7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        const Text(
          'Product lines use catalog prices; bundle lines use the package price shown in your bag.',
          style: TextStyle(color: muted, fontSize: 11, height: 1.5),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _placeButton(
    double total,
    List<Map<String, dynamic>> cart,
    Map<String, Map<String, dynamic>> byId,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: loading ? null : () => _placeOrder(total, cart, byId),
        icon: loading
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: Text(
          loading ? 'Placing order...' : 'Place order',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(color: Color(0x07172554), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: softBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: blue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: muted, fontSize: 12, height: 1.45)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _decoration(
    String label,
    IconData icon, {
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: alignLabelWithHint ? null : Icon(icon, size: 20),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: const Color(0xFFFAF8F3),
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB42318)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.5),
      ),
    );
  }

  Widget _emptyCart(BuildContext context) {
    return _state(
      icon: Icons.shopping_bag_outlined,
      title: 'Your bag is empty',
      message: 'Add something useful for your next class before checking out.',
      actionLabel: 'Browse shop',
      onAction: () => Navigator.pushNamed(context, '/shop'),
    );
  }

  Widget _auth(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Checkout')),
      body: _state(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to checkout',
        message: 'Sign in to continue with your delivery details and order.',
        actionLabel: 'Sign in',
        onAction: () => Navigator.pushNamed(context, '/login'),
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }

  Widget _state({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
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
                width: 82,
                height: 82,
                decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(26)),
                child: Icon(icon, color: blue, size: 38),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ink, fontSize: 23, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, height: 1.55),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
