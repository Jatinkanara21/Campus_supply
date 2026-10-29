import 'package:flutter/material.dart';

import '../database/firestore_database.dart';

class DemoPaymentScreen extends StatefulWidget {
  const DemoPaymentScreen({
    super.key,
    required this.checkoutData,
  });

  final Map<String, dynamic> checkoutData;

  @override
  State<DemoPaymentScreen> createState() => _DemoPaymentScreenState();
}

class _DemoPaymentScreenState extends State<DemoPaymentScreen> {
  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const green = Color(0xFF15803D);
  static const red = Color(0xFFB42318);

  bool processing = false;
  bool completed = false;
  bool simulatedFailure = false;
  bool cartClearFailed = false;
  String? orderId;
  String? transactionId;
  String? errorMessage;

  String get paymentMethod => (widget.checkoutData['paymentMethod'] ?? 'demo_upi').toString();
  String get methodLabel => paymentMethod == 'demo_card' ? 'Card · Demo' : 'UPI · Demo';

  double get total {
    final value = widget.checkoutData['total'];
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  Future<void> _simulateFailure() async {
    if (processing || completed) return;
    setState(() {
      simulatedFailure = true;
      errorMessage = null;
    });
  }

  Future<void> _simulateSuccess() async {
    if (processing || completed) return;
    setState(() {
      processing = true;
      simulatedFailure = false;
      errorMessage = null;
    });

    try {
      final uid = (widget.checkoutData['uid'] ?? '').toString();
      final rawItems = widget.checkoutData['items'];
      final items = rawItems is List
          ? rawItems.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
          : <Map<String, dynamic>>[];
      if (uid.isEmpty || items.isEmpty) {
        throw StateError('Checkout information is missing. Please return to your bag and try again.');
      }

      final result = await FirestoreDatabase.instance.createOrder(
        uid: uid,
        items: items,
        total: total,
        paymentMethod: paymentMethod,
        customerName: (widget.checkoutData['customerName'] ?? '').toString(),
        customerPhone: (widget.checkoutData['customerPhone'] ?? '').toString(),
        customerEmail: (widget.checkoutData['customerEmail'] ?? '').toString(),
        deliveryAddress: (widget.checkoutData['deliveryAddress'] ?? '').toString(),
        deliveryCity: (widget.checkoutData['deliveryCity'] ?? '').toString(),
        deliveryPinCode: (widget.checkoutData['deliveryPinCode'] ?? '').toString(),
      );

      if (!mounted) return;
      setState(() {
        completed = true;
        orderId = result.orderId;
        transactionId = result.demoTransactionId;
      });

      try {
        await FirestoreDatabase.instance.clearCart(uid);
      } catch (_) {
        if (!mounted) return;
        setState(() => cartClearFailed = true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        simulatedFailure = true;
        errorMessage = error is StateError
            ? error.toString().replaceFirst('Bad state: ', '')
            : 'The order could not be completed. Please check your connection and try again.';
      });
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Demo payment', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 36),
            shrinkWrap: true,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.lock_outline_rounded, color: blue, size: 31),
              ),
              const SizedBox(height: 18),
              Text(
                completed ? 'Demo payment successful' : 'Complete your demo payment',
                style: const TextStyle(color: ink, fontSize: 27, height: 1.15, letterSpacing: -.6, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              const Text(
                'This is a simulated payment for a faculty demonstration. No real money will be charged.',
                style: TextStyle(color: muted, fontSize: 13, height: 1.55),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('PAYMENT SUMMARY', style: TextStyle(color: muted, fontSize: 10, letterSpacing: .9, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 13),
                  Row(children: [
                    const Icon(Icons.payments_outlined, color: blue, size: 21),
                    const SizedBox(width: 10),
                    Expanded(child: Text(methodLabel, style: const TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w900))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFFFF0BF), borderRadius: BorderRadius.circular(8)),
                      child: const Text('DEMO ONLY', style: TextStyle(color: Color(0xFF946200), fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                  ]),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                  Row(children: [
                    const Expanded(child: Text('Amount to simulate', style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600))),
                    Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: blue, fontSize: 26, fontWeight: FontWeight.w900)),
                  ]),
                ]),
              ),
              if (processing) ...[
                const SizedBox(height: 18),
                const LinearProgressIndicator(minHeight: 3, color: blue),
                const SizedBox(height: 10),
                const Text('Processing simulated payment and validating stock…', textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
              if (simulatedFailure && !completed) ...[
                const SizedBox(height: 18),
                _outcomePanel(
                  success: false,
                  title: errorMessage == null ? 'Payment failed (simulated)' : 'Order could not be completed',
                  message: errorMessage ??
                      'No order was created and no stock was changed. You can retry the demo or return to checkout.',
                ),
              ],
              if (completed) ...[
                const SizedBox(height: 18),
                _outcomePanel(success: true, title: 'Order placed successfully',
                    message: 'Your demo payment was recorded. No real money was charged.'),
                const SizedBox(height: 14),
                _detailRow('ORDER ID', orderId ?? 'Unavailable'),
                if (transactionId != null) _detailRow('DEMO TRANSACTION', transactionId!),
                _detailRow('PAYMENT STATUS', 'Paid · Demo'),
                if (cartClearFailed) ...[
                  const SizedBox(height: 10),
                  const Text('The order was placed, but the bag could not be cleared. Check My Orders before trying another purchase.',
                      style: TextStyle(color: red, fontSize: 12, height: 1.45)),
                ],
              ],
              const SizedBox(height: 20),
              if (completed) ...[
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/orders', (_) => false),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('View My Orders'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
                    child: const Text('Continue shopping'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: processing ? null : _simulateSuccess,
                    icon: processing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(processing ? 'Processing…' : 'Simulate successful payment'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: processing ? null : _simulateFailure,
                    icon: const Icon(Icons.error_outline_rounded, color: red),
                    label: const Text('Simulate failed payment', style: TextStyle(color: red)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: processing ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to checkout'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _outcomePanel({
    required bool success,
    required String title,
    required String message,
  }) {
    final color = success ? green : red;
    final background = success ? const Color(0xFFECFDF3) : const Color(0xFFFFF0EF);
    final stroke = success ? const Color(0xFFB7E4C7) : const Color(0xFFF4C7C3);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(15), border: Border.all(color: stroke)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(success ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(message, style: TextStyle(color: color, fontSize: 11, height: 1.5)),
        ])),
      ]),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 145, child: Text(label, style: const TextStyle(color: muted, fontSize: 10, letterSpacing: .5, fontWeight: FontWeight.w900))),
        const SizedBox(width: 10),
        Expanded(child: SelectableText(value, style: const TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}
