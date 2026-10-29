import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/customer_bottom_nav.dart';

import '../database/firestore_database.dart';
import '../database/local_demo_orders.dart';
import '../widgets/app_image.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const green = Color(0xFF15803D);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const softBlue = Color(0xFFEAF2FF);
  static const amber = Color(0xFF9A6700);
  static const red = Color(0xFFB42318);

  List<Map<String, dynamic>> _localOrders = <Map<String, dynamic>>[];
  bool _localOrdersLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLocalOrders();
  }

  Future<void> _loadLocalOrders() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _localOrdersLoaded = true);
      return;
    }
    try {
      final localOrders = await LocalDemoOrders.readForUser(uid);
      if (!mounted) return;
      setState(() {
        _localOrders = localOrders;
        _localOrdersLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _localOrdersLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _auth(context);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('My orders', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Shop',
            onPressed: () => Navigator.pushNamed(context, '/shop'),
            icon: const Icon(Icons.add_shopping_cart_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchOrders(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _state(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load orders',
              subtitle: 'Please try again in a moment.',
            );
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final orders = <Map<String, dynamic>>[
            ...snapshot.data!,
            ..._localOrders,
          ]..sort((a, b) {
              final aDate = _dateTimeValue(a['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = _dateTimeValue(b['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });
          if (orders.isEmpty && !_localOrdersLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (orders.isEmpty) {
            return _state(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Your purchases will appear here after you place an order.',
              action: 'Start shopping',
              onPressed: () => Navigator.pushNamed(context, '/shop'),
            );
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreDatabase.instance.watchProducts(),
            builder: (context, productSnapshot) {
              final productsById = <String, Map<String, dynamic>>{
                if (productSnapshot.hasData)
                  for (final product in productSnapshot.data!)
                    product['id'].toString(): product,
              };

              return LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal = constraints.maxWidth >= 900 ? 30.0 : 16.0;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, 36),
                        children: [
                          _pageIntro(orders.length),
                          const SizedBox(height: 22),
                          ...orders.map((order) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _orderCard(context, order, productsById),
                          )),
                        ],
                      ),
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

  Widget _pageIntro(int orderCount) {
    final orderWord = orderCount == 1 ? 'order' : 'orders';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your order history',
                style: TextStyle(
                  color: ink,
                  fontSize: 27,
                  height: 1.14,
                  letterSpacing: -0.7,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'View the status and total for your purchases.',
                style: TextStyle(color: muted, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(14)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                orderCount.toString(),
                style: const TextStyle(color: blue, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              Text(
                orderWord.toUpperCase(),
                style: const TextStyle(color: muted, fontSize: 8, letterSpacing: .7, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _orderCard(
    BuildContext context,
    Map<String, dynamic> order,
    Map<String, Map<String, dynamic>> productsById,
  ) {
    final id = (order['id'] ?? '').toString();
    final status = (order['status'] ?? 'pending').toString();
    final normalizedStatus = status.toLowerCase().trim();
    final statusColor = _statusColor(normalizedStatus);
    final rawTotal = order['total'];
    final total = rawTotal is num
        ? rawTotal.toDouble()
        : double.tryParse((rawTotal ?? '').toString()) ?? 0;
    final rawItems = order['items'] is List ? order['items'] as List : const <dynamic>[];
    final items = rawItems.whereType<Map>().toList();
    final itemCount = items.fold<int>(0, (sum, entry) {
      final quantity = entry['quantity'];
      if (quantity is num) return sum + (quantity.toInt() < 0 ? 0 : quantity.toInt());
      return sum + 1;
    });
    final date = _formatOrderDate(order['createdAt']);
    final cancelled = normalizedStatus == 'cancelled';
    final firstItem = items.isEmpty ? null : items.first;
    final previewName = firstItem == null
        ? 'Item details unavailable'
        : (firstItem['name'] ?? firstItem['title'] ?? 'Order item').toString();
    final firstIsBundle = firstItem != null && (firstItem['itemType'] ?? '').toString() == 'bundle';
    final previewIncluded = firstIsBundle ? _includedItemNames(firstItem!) : <String>[];
    final previewText = firstIsBundle && previewIncluded.isNotEmpty
        ? 'Bundle · Includes ' + previewIncluded.join(', ')
        : items.length > 1
            ? 'Plus ' + (items.length - 1).toString() + (items.length == 2 ? ' more item' : ' more items')
            : firstIsBundle
                ? 'Bundle package'
                : 'Purchased item';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(color: Color(0x07172554), blurRadius: 18, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(14)),
                child: Icon(cancelled ? Icons.receipt_long_rounded : Icons.inventory_2_outlined, color: blue, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ORDER ID',
                        style: TextStyle(color: muted, fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        id.isEmpty ? 'Order ID unavailable' : '#' + id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                      if (date != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: muted, size: 12),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(date, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(status, statusColor),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Wrap(
            spacing: 28,
            runSpacing: 14,
            children: [
              _orderMetric(
                label: 'ORDER TOTAL',
                value: '₹' + total.toStringAsFixed(0),
                icon: Icons.currency_rupee_rounded,
                prominent: true,
              ),
              _orderMetric(
                label: 'ITEMS',
                value: itemCount.toString(),
                icon: Icons.shopping_bag_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _paymentInfo(order),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE8EDF5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 42,
                  decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(11)),
                  child: Icon(firstIsBundle ? Icons.all_inbox_rounded : Icons.shopping_bag_outlined, color: blue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        previewName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        previewText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: muted, fontSize: 10, height: 1.35, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: muted, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: softBlue,
              highlightColor: softBlue.withValues(alpha: .4),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 2),
              childrenPadding: const EdgeInsets.only(top: 6, bottom: 4),
              shape: const Border(),
              collapsedShape: const Border(),
              title: const Text(
                'View full order details',
                style: TextStyle(color: blue, fontSize: 12, fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                items.isEmpty
                    ? 'No item details were saved for this order'
                    : items.length.toString() + (items.length == 1 ? ' order line' : ' order lines'),
                style: const TextStyle(color: muted, fontSize: 10, height: 1.4),
              ),
              children: [
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Item names are not available in this historical order record.',
                      style: TextStyle(color: muted, fontSize: 12, height: 1.5),
                    ),
                  )
                else
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _orderLineItem(item, productsById),
                  )),
                if ((order['paymentMethod'] ?? '').toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _paymentInfo(order, showTransactionId: true),
                ],
                if ((order['customerName'] ?? '').toString().trim().isNotEmpty ||
                    (order['deliveryAddress'] ?? '').toString().trim().isNotEmpty)
                  _deliverySummary(order),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (cancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(color: const Color(0xFFFFE9E6), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined, color: red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This order is marked as ' + _displayStatus(status) + '.',
                      style: const TextStyle(color: red, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          else if (const ['pending', 'confirmed', 'shipped', 'delivered'].contains(normalizedStatus))
            _statusTimeline(normalizedStatus)
          else
            Text(
              'Current status: ' + _displayStatus(status),
              style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _paymentInfo(
    Map<String, dynamic> order, {
    bool showTransactionId = false,
  }) {
    final method = (order['paymentMethod'] ?? '').toString().trim().toLowerCase();
    final status = (order['paymentStatus'] ?? '').toString().trim().toLowerCase();
    if (method.isEmpty && status.isEmpty) return const SizedBox.shrink();

    final methodLabel = switch (method) {
      'demo_upi' => 'UPI · Demo',
      'demo_card' => 'Card · Demo',
      'cash_on_delivery' => 'Cash on Delivery',
      _ => method.isEmpty ? 'Payment method unavailable' : method,
    };
    final statusLabel = switch (status) {
      'success' => method.startsWith('demo_') ? 'Paid · Demo' : 'Paid',
      'pending' => method == 'cash_on_delivery' ? 'Pay on delivery' : 'Pending',
      'failed' => 'Failed',
      'refunded' => 'Refunded',
      _ => status.isEmpty ? 'Payment details unavailable' : status,
    };
    final paid = status == 'success';
    final color = paid ? green : status == 'failed' ? red : const Color(0xFF946200);
    final transactionId = (order['demoTransactionId'] ?? '').toString().trim();
    final isDemo = (order['paymentMode'] ?? '').toString() == 'demo';
    final isLocalDemo = order['isLocalDemo'] == true;
    final paymentIdentifier =
        (order['paymentIdentifier'] ?? '').toString().trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.payments_outlined, color: blue, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PAYMENT', style: TextStyle(color: muted, fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(methodLabel, style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w800)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(8)),
            child: Text(statusLabel, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ]),
        if (isDemo) ...[
          const SizedBox(height: 7),
          const Text('Simulated payment · No real money charged', style: TextStyle(color: muted, fontSize: 10, height: 1.4)),
        ],
        if (isLocalDemo) ...[
          const SizedBox(height: 7),
          const Text('Saved on this device only · Not synced to the admin dashboard', style: TextStyle(color: muted, fontSize: 10, height: 1.4)),
        ],
        if (showTransactionId && paymentIdentifier.isNotEmpty) ...[
          const SizedBox(height: 8),
          SelectableText('Payment detail: ' + paymentIdentifier, style: const TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
        if (showTransactionId && transactionId.isNotEmpty) ...[
          const SizedBox(height: 8),
          SelectableText('Demo transaction: ' + transactionId, style: const TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ]),
    );
  }

  Widget _orderLineItem(Map item, Map<String, Map<String, dynamic>> productsById) {
    final isBundle = (item['itemType'] ?? '').toString() == 'bundle';
    final productId = (item['productId'] ?? '').toString();
    final product = isBundle ? null : productsById[productId];
    final name = (item['name'] ?? item['title'] ?? (isBundle ? 'Student Bundle' : 'Product')).toString();
    final rawPrice = item['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse((rawPrice ?? '').toString());
    final rawQuantity = item['quantity'];
    final quantity = rawQuantity is num ? rawQuantity.toInt() : 1;
    final lineTotal = price == null ? null : price * quantity;
    final savedImage = (item['imageUrl'] ?? item['bundleImageUrl'] ?? '').toString().trim();
    final image = savedImage.isNotEmpty
        ? savedImage
        : (product?['imageUrl'] ?? '').toString().trim();
    final imageSource = image.isNotEmpty ? image : _fallbackOrderImage(name, product, isBundle);
    final includedNames = isBundle ? _includedItemNames(item) : <String>[];
    final category = isBundle
        ? (includedNames.isNotEmpty ? 'Bundle · ' + includedNames.join(', ') : 'Bundle package')
        : (product?['category'] ?? 'Product').toString();

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 72,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: AppImage(
                source: imageSource,
                fit: BoxFit.contain,
                fallback: Center(child: Icon(isBundle ? Icons.all_inbox_rounded : Icons.shopping_bag_outlined, color: blue, size: 27)),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ink, fontSize: 12, height: 1.35, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(category, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 10, height: 1.35, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  price == null ? 'Price unavailable' : '₹' + price.toStringAsFixed(0) + ' each · Qty ' + quantity.toString(),
                  style: const TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (lineTotal != null) ...[
            const SizedBox(width: 8),
            Text(
              '₹' + lineTotal.toStringAsFixed(0),
              style: const TextStyle(color: blue, fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _includedItemNames(Map item) {
    final raw = item['includedItems'];
    if (raw is! List) return <String>[];
    return raw.whereType<Map>()
        .map((entry) => (entry['name'] ?? entry['title'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  String _fallbackOrderImage(String name, Map<String, dynamic>? product, bool isBundle) {
    final value = (name + ' ' + (product?['category'] ?? '').toString()).toLowerCase();
    if (value.contains('backpack') || value.contains('bag') || value.contains('campus daily')) return 'assets/image/products/backpack.svg';
    if (value.contains('headphone')) return 'assets/image/products/headphones.svg';
    if (value.contains('bottle') || value.contains('tumbler')) return 'assets/image/products/bottle.svg';
    if (value.contains('calculator') || value.contains('exam')) return 'assets/image/products/calculator.svg';
    if (value.contains('lamp') || value.contains('study smart')) return 'assets/image/products/lamp.svg';
    if (value.contains('sleeve')) return 'assets/image/products/sleeve.svg';
    if (value.contains('pen')) return 'assets/image/products/pen.svg';
    if (value.contains('notebook') || value.contains('stationery')) return 'assets/image/products/notebook.svg';
    return isBundle ? 'assets/image/products/backpack.svg' : '';
  }

  DateTime? _dateTimeValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String? _formatOrderDate(Object? value) {
    final date = _dateTimeValue(value);
    if (date == null) return null;

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year} • $hour:$minute $period';
  }

  Widget _deliverySummary(Map<String, dynamic> order) {
    final name = (order['customerName'] ?? '').toString().trim();
    final phone = (order['customerPhone'] ?? '').toString().trim();
    final email = (order['customerEmail'] ?? '').toString().trim();
    final address = (order['deliveryAddress'] ?? '').toString().trim();
    final city = (order['deliveryCity'] ?? '').toString().trim();
    final pin = (order['deliveryPinCode'] ?? '').toString().trim();
    final parts = [address, city, pin].where((value) => value.isNotEmpty).toList();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(13)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('DELIVERY DETAILS', style: TextStyle(color: ink, fontSize: 10, letterSpacing: .7, fontWeight: FontWeight.w900)),
        if (name.isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(name, style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
        if (phone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(phone, style: const TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
        if (email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
        if (parts.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(parts.join(', '), style: const TextStyle(color: ink, fontSize: 11, height: 1.45)),
        ],
      ]),
    );
  }

  Widget _statusTimeline(String status) {
    const labels = ['Pending', 'Confirmed', 'Shipped', 'Delivered'];
    const icons = [
      Icons.schedule_rounded,
      Icons.verified_outlined,
      Icons.local_shipping_outlined,
      Icons.check_circle_outline_rounded,
    ];
    final currentStep = labels.indexWhere((label) => label.toLowerCase() == status);
    if (currentStep < 0) {
      return Text('Current status: ' + _displayStatus(status),
          style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ORDER PROGRESS',
            style: TextStyle(color: muted, fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w900)),
        const SizedBox(height: 13),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(labels.length, (index) {
            final completed = index < currentStep;
            final active = index == currentStep;
            final dotColor = active ? blue : completed ? green : const Color(0xFFE2E8F0);
            final iconColor = active || completed ? Colors.white : muted;
            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(height: 2, color: index <= currentStep ? green : const Color(0xFFE2E8F0)),
                        ),
                      Container(
                        width: 23,
                        height: 23,
                        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                        child: Icon(completed ? Icons.check_rounded : icons[index], color: iconColor, size: 13),
                      ),
                      if (index < labels.length - 1)
                        Expanded(
                          child: Container(height: 2, color: index < currentStep ? green : const Color(0xFFE2E8F0)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(labels[index], maxLines: 1, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: active ? blue : completed ? green : muted, fontSize: 9, fontWeight: active ? FontWeight.w900 : FontWeight.w700)),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Text(
        status.isEmpty ? 'UNKNOWN' : status.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 9, letterSpacing: .35, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _orderMetric({
    required String label,
    required String value,
    required IconData icon,
    bool prominent = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: prominent ? const Color(0xFFFFF4D5) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 17, color: prominent ? const Color(0xFF946200) : muted),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: muted, fontSize: 9, letterSpacing: .7, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: prominent ? blue : ink,
                fontSize: prominent ? 22 : 17,
                fontWeight: FontWeight.w900,
                letterSpacing: prominent ? -0.5 : 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return amber;
      case 'confirmed':
        return blue;
      case 'shipped':
        return const Color(0xFF4F46E5);
      case 'delivered':
        return green;
      case 'cancelled':
        return red;
      default:
        return muted;
    }
  }

  static String _displayStatus(String status) {
    final value = status.trim();
    if (value.isEmpty) return 'Unknown';
    return value[0].toUpperCase() + value.substring(1);
  }

  Widget _auth(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Orders')),
      body: _state(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to view orders',
        subtitle: 'Your order history is available after you sign in.',
        action: 'Sign in',
        onPressed: () => Navigator.pushNamed(context, '/login'),
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }

  Widget _state({
    required IconData icon,
    required String title,
    required String subtitle,
    String? action,
    VoidCallback? onPressed,
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
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(26)),
                child: Icon(icon, color: blue, size: 39),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ink, fontSize: 23, letterSpacing: -0.4, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, height: 1.55, fontSize: 13),
              ),
              if (action != null && onPressed != null) ...[
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: Text(action),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
