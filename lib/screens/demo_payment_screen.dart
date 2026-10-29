import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  final _formKey = GlobalKey<FormState>();
  final _paymentIdentifierController = TextEditingController();

  /// One idempotency key per checkout attempt: pressing Pay Now again after
  /// an error re-uses it, so the order can never be saved twice.
  late final String _orderKey = FirestoreDatabase.instance.newOrderKey();

  bool processing = false;
  bool completed = false;
  bool cartClearFailed = false;
  String? orderId;
  String? transactionId;
  String? errorMessage;

  String get paymentMethod =>
      (widget.checkoutData['paymentMethod'] ?? 'demo_upi').toString();

  bool get isCardPayment => paymentMethod == 'demo_card';

  String get methodLabel => isCardPayment ? 'Card payment' : 'UPI payment';

  String get paymentDetailLabel => isCardPayment ? 'Card number' : 'UPI ID';

  String get paymentIdentifierHint =>
      isCardPayment ? '1111 2222 3333 4444' : 'student.demo@upi';

  String get displayedIdentifier {
    final value = _paymentIdentifierController.text.trim();
    if (!isCardPayment) return value;
    final digits = value.replaceAll(RegExp('[^0-9]'), '');
    if (digits.length < 4) return '••••';
    return '•••• •••• •••• ' + digits.substring(digits.length - 4);
  }

  double get total {
    final value = widget.checkoutData['total'];
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  @override
  void dispose() {
    _paymentIdentifierController.dispose();
    super.dispose();
  }

  String? _validatePaymentIdentifier(String? rawValue) {
    final value = (rawValue ?? '').trim();

    if (isCardPayment) {
      final digits = value.replaceAll(RegExp('[^0-9]'), '');
      if (digits.length != 16) {
        return 'Enter a 16-digit demo card number.';
      }
      return null;
    }

    final isValidUpi = RegExp(
      r'^[A-Za-z0-9._-]{2,}@[A-Za-z][A-Za-z0-9.-]{1,}$',
    ).hasMatch(value);
    if (!isValidUpi || value.endsWith('.') || value.contains('..')) {
      return 'Enter a valid demo UPI ID, e.g. student.demo@upi (no final dot).';
    }
    return null;
  }

  Future<void> _completePayment() async {
    if (processing || completed) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      processing = true;
      errorMessage = null;
    });

    try {
      final uid = (widget.checkoutData['uid'] ?? '').toString();
      final rawItems = widget.checkoutData['items'];
      final items = rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      if (uid.isEmpty || items.isEmpty) {
        throw StateError(
          'Checkout information is missing. Please return to checkout and try again.',
        );
      }

      // Demo payment only: no real gateway is called and the card/UPI value is
      // never saved. The order and the stock change are written to Firestore
      // in ONE transaction; success is shown only after it commits.
      final result = await FirestoreDatabase.instance.createOrder(
        uid: uid,
        orderKey: _orderKey,
        items: items,
        total: total,
        paymentMethod: paymentMethod,
        customerName: (widget.checkoutData['customerName'] ?? '').toString(),
        customerPhone: (widget.checkoutData['customerPhone'] ?? '').toString(),
        customerEmail: (widget.checkoutData['customerEmail'] ?? '').toString(),
        deliveryAddress:
            (widget.checkoutData['deliveryAddress'] ?? '').toString(),
        deliveryCity: (widget.checkoutData['deliveryCity'] ?? '').toString(),
        deliveryPinCode:
            (widget.checkoutData['deliveryPinCode'] ?? '').toString(),
      );

      if (!mounted) return;
      setState(() {
        completed = true;
        orderId = result.orderId;
        transactionId = result.demoTransactionId;
      });

      // The order is already saved in Firestore. Clearing the bag is a
      // separate step; if it fails we say so, but the order stays valid.
      try {
        await FirestoreDatabase.instance
            .clearCart(uid)
            .timeout(const Duration(seconds: 10));
      } catch (error) {
        debugPrint('clearCart after order ${result.orderId} failed: $error');
        if (!mounted) return;
        setState(() => cartClearFailed = true);
      }
    } on OrderException catch (error) {
      debugPrint('Pay Now failed [${error.code}]: ${error.message}');
      if (!mounted) return;
      setState(() => errorMessage = error.message);
    } catch (error, stackTrace) {
      debugPrint('Pay Now failed (unexpected): $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
      if (!mounted) return;
      setState(() {
        errorMessage = error is StateError
            ? error.message
            : 'The order could not be saved. Please try again.';
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
        title: Text(
          completed ? 'Payment confirmation' : 'Payment',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
            children: completed ? _successContent() : _paymentContent(),
          ),
        ),
      ),
    );
  }

  List<Widget> _paymentContent() {
    return [
      Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCardPayment
                  ? Icons.credit_card_rounded
                  : Icons.account_balance_wallet_outlined,
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
                  'Complete your payment',
                  style: TextStyle(
                    color: ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enter the details for your selected method.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ORDER PAYMENT',
              style: TextStyle(
                color: muted,
                fontSize: 10,
                letterSpacing: .9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: Text(
                    methodLabel,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '₹' + total.toStringAsFixed(0),
                  style: const TextStyle(
                    color: blue,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 15, color: muted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Demo payment only · No real money charged',
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: border),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCardPayment ? 'CARD DETAILS' : 'UPI DETAILS',
                style: const TextStyle(
                  color: ink,
                  fontSize: 12,
                  letterSpacing: .6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _paymentIdentifierController,
                keyboardType: isCardPayment
                    ? TextInputType.number
                    : TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                inputFormatters: isCardPayment
                    ? <TextInputFormatter>[_DemoCardNumberFormatter()]
                    : const <TextInputFormatter>[],
                maxLength: isCardPayment ? 19 : 80,
                validator: _validatePaymentIdentifier,
                decoration: InputDecoration(
                  labelText: paymentDetailLabel,
                  hintText: paymentIdentifierHint,
                  prefixIcon: Icon(
                    isCardPayment
                        ? Icons.credit_card_rounded
                        : Icons.alternate_email_rounded,
                    color: blue,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: blue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Use sample details only. Do not enter a real card number, CVV, UPI PIN or OTP. These details are not sent to the payment service.',
                style: TextStyle(color: muted, fontSize: 10, height: 1.5),
              ),
            ],
          ),
        ),
      ),
      if (errorMessage != null) ...[
        const SizedBox(height: 14),
        _messagePanel(
          success: false,
          title: 'Payment was not completed',
          message: errorMessage!,
        ),
      ],
      if (processing) ...[
        const SizedBox(height: 17),
        const LinearProgressIndicator(minHeight: 3, color: blue),
        const SizedBox(height: 9),
        const Text(
          'Saving your order and updating stock…',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ],
      const SizedBox(height: 22),
      SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: processing ? null : _completePayment,
          icon: processing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.lock_rounded),
          label: Text(
            processing ? 'Processing…' : 'Pay ₹' + total.toStringAsFixed(0) + ' now',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      const SizedBox(height: 9),
      SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: processing ? null : () => Navigator.pop(context),
          child: const Text('Back to checkout'),
        ),
      ),
    ];
  }

  List<Widget> _successContent() {
    return [
      Container(
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.check_circle_rounded, color: green, size: 46),
      ),
      const SizedBox(height: 20),
      const Text(
        'Payment successful!',
        style: TextStyle(
          color: ink,
          fontSize: 29,
          fontWeight: FontWeight.w900,
          letterSpacing: -.6,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Your order has been saved. This was a demo payment; no real money was charged.',
        style: TextStyle(color: muted, fontSize: 13, height: 1.6),
      ),
      const SizedBox(height: 22),
      _messagePanel(
        success: true,
        title: 'Order confirmed',
        message: 'Your order is saved to your account and visible in My Orders and the admin dashboard. Card/UPI details are not stored.',
      ),
      const SizedBox(height: 17),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PAYMENT DETAILS',
              style: TextStyle(
                color: muted,
                fontSize: 10,
                letterSpacing: .9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            _detailRow('Amount', '₹' + total.toStringAsFixed(0)),
            _detailRow('Method', isCardPayment ? 'Card · Demo' : 'UPI · Demo'),
            _detailRow(paymentDetailLabel, displayedIdentifier),
            _detailRow('Payment status', 'Successful · Demo'),
            if ((transactionId ?? '').isNotEmpty)
              _detailRow('Transaction ID', transactionId!),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            const Text(
              'ORDER DETAILS',
              style: TextStyle(
                color: muted,
                fontSize: 10,
                letterSpacing: .9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            _detailRow('Order ID', orderId ?? 'Unavailable'),
          ],
        ),
      ),
      if (cartClearFailed) ...[
        const SizedBox(height: 13),
        const Text(
          'Your order is saved, but the bag could not be cleared. Check My Orders before ordering again.',
          style: TextStyle(color: red, fontSize: 12, height: 1.5),
        ),
      ],
      const SizedBox(height: 22),
      SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/orders',
            (_) => false,
          ),
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('Check your order'),
        ),
      ),
      const SizedBox(height: 9),
      SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (_) => false,
          ),
          child: const Text('Continue shopping'),
        ),
      ),
    ];
  }

  Widget _messagePanel({
    required bool success,
    required String title,
    required String message,
  }) {
    final color = success ? green : red;
    final background =
        success ? const Color(0xFFECFDF3) : const Color(0xFFFFF0EF);
    final stroke =
        success ? const Color(0xFFB7E4C7) : const Color(0xFFF4C7C3);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(color: color, fontSize: 11, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoCardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawDigits = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    final digits =
        rawDigits.length > 16 ? rawDigits.substring(0, 16) : rawDigits;

    final chunks = <String>[];
    for (var start = 0; start < digits.length; start += 4) {
      final end = (start + 4) > digits.length ? digits.length : start + 4;
      chunks.add(digits.substring(start, end));
    }
    final formatted = chunks.join(' ');

    final cursorBefore =
        newValue.selection.end.clamp(0, newValue.text.length).toInt();
    final digitsBeforeCursor = newValue.text
        .substring(0, cursorBefore)
        .replaceAll(RegExp('[^0-9]'), '')
        .length
        .clamp(0, digits.length)
        .toInt();
    final formattedCursor = (digitsBeforeCursor == 0
            ? 0
            : digitsBeforeCursor + ((digitsBeforeCursor - 1) ~/ 4))
        .clamp(0, formatted.length)
        .toInt();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formattedCursor),
      composing: TextRange.empty,
    );
  }
}
