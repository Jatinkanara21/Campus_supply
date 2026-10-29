import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Result of creating an order with [FirestoreDatabase.createOrder].
class OrderCreationResult {
  const OrderCreationResult({
    required this.orderId,
    this.demoTransactionId,
    this.alreadyExisted = false,
  });

  final String orderId;
  final String? demoTransactionId;

  /// True when a retry found the order this checkout attempt had already saved.
  final bool alreadyExisted;
}

/// An order / stock error with a message that is safe to show to the user.
class OrderException implements Exception {
  const OrderException(this.code, this.message);

  /// Builds a user-facing message from a Firebase (or other) error.
  factory OrderException.fromError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return const OrderException(
            'permission-denied',
            'Your account is not allowed to place this order. Please sign out, sign in again and retry.',
          );
        case 'unauthenticated':
          return const OrderException(
            'unauthenticated',
            'Your session has expired. Please sign in again and retry.',
          );
        case 'unavailable':
        case 'deadline-exceeded':
          return const OrderException(
            'unavailable',
            'Could not reach the store server. Check your internet connection and press Pay Now again. You will not be charged twice.',
          );
        case 'aborted':
        case 'failed-precondition':
          return const OrderException(
            'busy',
            'Stock changed while your order was being saved. Please press Pay Now again.',
          );
        case 'resource-exhausted':
          return const OrderException(
            'busy',
            'The store is busy right now. Please wait a minute and try again.',
          );
        default:
          return OrderException(
            error.code,
            'The order could not be saved (${error.code}). Please try again.',
          );
      }
    }
    if (error is StateError) {
      return OrderException('error', error.message);
    }
    return const OrderException(
      'unknown',
      'The order could not be saved. Please try again.',
    );
  }

  final String code;
  final String message;

  @override
  String toString() => message;
}

/// Firestore data layer for Campus Supply.
///
/// Expected top-level collections:
/// users, products, categories, bundles, wishlists, carts, orders, reviews.
class FirestoreDatabase {
  FirestoreDatabase._();

  static final FirestoreDatabase instance = FirestoreDatabase._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get products => _db.collection('products');
  CollectionReference<Map<String, dynamic>> get categories => _db.collection('categories');
  CollectionReference<Map<String, dynamic>> get bundles => _db.collection('bundles');
  CollectionReference<Map<String, dynamic>> get wishlists => _db.collection('wishlists');
  CollectionReference<Map<String, dynamic>> get carts => _db.collection('carts');
  CollectionReference<Map<String, dynamic>> get orders => _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get reviews => _db.collection('reviews');

  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    String role = 'user',
  }) {
    return users.doc(uid).set({
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return users.doc(uid).get();
  }

  Stream<List<Map<String, dynamic>>> watchProducts() {
    return products.snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      items.sort((a, b) {
        final ad = a['createdAt'];
        final bd = b['createdAt'];
        if (ad is Timestamp && bd is Timestamp) return bd.compareTo(ad);
        return 0;
      });
      return items;
    });
  }

  Stream<List<Map<String, dynamic>>> watchCategories() {
    return categories.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  Stream<Map<String, dynamic>> watchHomeSettings() {
    return _db.collection('settings').doc('home').snapshots().map(
      (snapshot) => snapshot.data() ?? <String, dynamic>{},
    );
  }

  Future<void> saveHomeSettings({
    required String heroImageUrl,
  }) {
    return _db.collection('settings').doc('home').set({
      'heroImageUrl': heroImageUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveBannerImageSetting({
    required String field,
    required String imageUrl,
  }) {
    const allowedFields = {
      'heroImageUrl',
      'homeSecondaryBannerImageUrl',
      'shopBannerImageUrl',
    };
    if (!allowedFields.contains(field)) {
      throw ArgumentError.value(field, 'field', 'Unsupported banner setting.');
    }

    return _db.collection('settings').doc('home').set({
      field: imageUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> watchBundles() {
    return bundles.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  DocumentReference<Map<String, dynamic>> _cartReference({
    required String uid,
    required String itemId,
    required String itemType,
  }) => itemType == 'bundle'
      ? carts.doc('${uid}_bundle_${itemId}')
      : carts.doc('${uid}_${itemId}');

  Future<void> updateCartQuantity({
    required String uid,
    required String itemId,
    required int quantity,
    String itemType = 'product',
  }) async {
    final ref = _cartReference(uid: uid, itemId: itemId, itemType: itemType);
    if (quantity <= 0) {
      await ref.delete();
      return;
    }
    final data = <String, dynamic>{
      'userId': uid,
      'itemType': itemType,
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (itemType == 'bundle') {
      data['bundleId'] = itemId;
    } else {
      data['productId'] = itemId;
    }
    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> removeFromCart({
    required String uid,
    required String itemId,
    String itemType = 'product',
  }) => _cartReference(uid: uid, itemId: itemId, itemType: itemType).delete();

  Future<void> clearCart(String uid) async {
    final snapshot = await carts.where('userId', isEqualTo: uid).get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> watchOrders(String uid) {
    return orders.where('userId', isEqualTo: uid).snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      items.sort((a, b) {
        final ad = a['createdAt'];
        final bd = b['createdAt'];
        if (ad is Timestamp && bd is Timestamp) return bd.compareTo(ad);
        return 0;
      });
      return items;
    });
  }

  Future<void> upsertProduct({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return products.doc(id).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleWishlist({
    required String uid,
    required String productId,
  }) async {
    final ref = wishlists.doc('${uid}_${productId}');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      await ref.delete();
      return;
    }

    await ref.set({
      'userId': uid,
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchWishlist(String uid) {
    return wishlists
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  Future<void> addToCart({
    required String uid,
    required String productId,
    int quantity = 1,
  }) {
    return carts.doc('${uid}_${productId}').set({
      'userId': uid,
      'itemType': 'product',
      'productId': productId,
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Adds a complete bundle as one cart row, at the bundle's package price.
  Future<void> addBundleToCart({
    required String uid,
    required Map<String, dynamic> bundle,
    int quantity = 1,
  }) async {
    final bundleId = (bundle['id'] ?? '').toString().trim();
    if (bundleId.isEmpty) {
      throw ArgumentError.value(bundleId, 'bundle.id', 'A bundle ID is required.');
    }
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'Quantity must be at least one.');
    }
    final rawProductIds = bundle['productIds'];
    final productIds = rawProductIds is List
        ? rawProductIds.map((value) => value.toString().trim()).where((value) => value.isNotEmpty).toSet().toList()
        : <String>[];
    if (productIds.isEmpty) {
      throw StateError('Select included products for this bundle in Admin > Bundles before buying it.');
    }
    final bundleName = (bundle['name'] ?? bundle['title'] ?? 'Student Bundle').toString().trim();
    final rawPrice = bundle['price'];
    final bundlePrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse((rawPrice ?? '').toString());
    if (bundlePrice == null || bundlePrice < 0) {
      throw StateError('This bundle has an invalid package price. Please contact the store admin.');
    }

    final productSnapshots = await Future.wait(productIds.map((id) => products.doc(id).get()));
    final includedItems = productSnapshots.map((snapshot) {
      final product = snapshot.data() ?? <String, dynamic>{};
      return <String, dynamic>{
        'productId': snapshot.id,
        'name': (product['name'] ?? snapshot.id).toString(),
        'price': product['price'] ?? 0,
        'imageUrl': (product['imageUrl'] ?? '').toString(),
      };
    }).toList();

    final ref = carts.doc('${uid}_bundle_${bundleId}');
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      final storedQuantity = existing.data()?['quantity'];
      final currentQuantity = storedQuantity is num ? storedQuantity.toInt() : 0;
      transaction.set(ref, {
        'userId': uid,
        'itemType': 'bundle',
        'bundleId': bundleId,
        'bundleName': bundleName,
        'bundleDescription': (bundle['description'] ?? '').toString().trim(),
        'bundlePrice': bundlePrice,
        'bundleImageUrl': (bundle['imageUrl'] ?? bundle['image'] ?? '').toString().trim(),
        'includedProductIds': productIds,
        'includedItems': includedItems,
        'quantity': currentQuantity + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Stream<List<Map<String, dynamic>>> watchCart(String uid) {
    return carts
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // ---------------------------------------------------------------------------
  // Orders + stock (Spark plan, no Cloud Functions)
  //
  // The project is on the free Spark plan, so the placeOrder / updateOrderStatus
  // Cloud Functions are not deployed (calling them returned HTTP 404). The same
  // logic now runs here as Firestore transactions. firestore.rules only allow a
  // customer to lower a product's stock in the SAME transaction that creates
  // their own order, by exactly the amount written in that order.
  // ---------------------------------------------------------------------------

  /// Creates a new idempotency key for one checkout attempt.
  ///
  /// The key becomes the order document ID, so pressing Pay Now again (or a
  /// network retry) can never create a second order or deduct stock twice.
  String newOrderKey() => orders.doc().id;

  static const Set<String> _allowedPaymentMethods = <String>{
    'demo_upi',
    'demo_card',
    'cash_on_delivery',
  };

  static String _cleanText(Object? value) => (value ?? '').toString().trim();

  static double? _numberValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_cleanText(value));
  }

  static int _stockValue(Map<String, dynamic> productData) {
    final value = _numberValue(productData['stock']) ?? 0;
    if (value.isNaN || value <= 0) return 0;
    return value.floor();
  }

  static int? _quantityValue(Object? value) {
    if (value is int) return value;
    if (value is num && value == value.roundToDouble()) return value.toInt();
    return int.tryParse(_cleanText(value));
  }

  Future<OrderCreationResult> createOrder({
    required String uid,
    required String orderKey,
    required List<Map<String, dynamic>> items,
    required double total,
    required String paymentMethod,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryPinCode,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid) {
      throw const OrderException(
        'not-signed-in',
        'Please sign in again before placing your order.',
      );
    }
    final key = orderKey.trim();
    if (key.isEmpty || key.contains('/')) {
      throw const OrderException(
        'invalid-order',
        'Checkout information is missing. Please return to checkout and try again.',
      );
    }

    final name = customerName.trim();
    final phone = customerPhone.trim();
    final address = deliveryAddress.trim();
    final city = deliveryCity.trim();
    final pinCode = deliveryPinCode.trim();
    if (name.isEmpty || phone.isEmpty || address.isEmpty || city.isEmpty || pinCode.isEmpty) {
      throw const OrderException(
        'invalid-order',
        'Please complete all required delivery details.',
      );
    }

    final method = paymentMethod.trim().toLowerCase();
    if (!_allowedPaymentMethods.contains(method)) {
      throw const OrderException(
        'invalid-order',
        'Choose a valid demo payment method or Cash on Delivery.',
      );
    }
    final isDemoPayment = method != 'cash_on_delivery';
    final paymentMode = isDemoPayment ? 'demo' : 'cod';
    final paymentStatus = isDemoPayment ? 'success' : 'pending';
    final demoTransactionId = isDemoPayment
        ? 'DEMO-TXN-${key.substring(0, key.length < 12 ? key.length : 12).toUpperCase()}'
        : null;

    if (!total.isFinite || total < 0) {
      throw const OrderException(
        'invalid-order',
        'The order total is invalid. Please review your bag.',
      );
    }
    if (items.isEmpty) {
      throw const OrderException(
        'invalid-order',
        'Your bag is empty. Add an item before checkout.',
      );
    }

    final orderRef = orders.doc(key);
    // Errors raised by our own checks are remembered here and rethrown after
    // the transaction, so the exact message survives on every platform.
    OrderException? checkError;
    Never fail(String code, String message) {
      checkError = OrderException(code, message);
      throw checkError!;
    }

    try {
      return await _db.runTransaction<OrderCreationResult>((transaction) async {
        // 1. Idempotency: if this checkout attempt already created its order,
        //    return that order and change nothing.
        final existingOrder = await transaction.get(orderRef);
        if (existingOrder.exists) {
          final existing = existingOrder.data() ?? <String, dynamic>{};
          if (_cleanText(existing['userId']) != uid) {
            fail('invalid-order', 'This checkout could not be completed. Please start checkout again.');
          }
          final existingTxn = _cleanText(existing['demoTransactionId']);
          return OrderCreationResult(
            orderId: existingOrder.id,
            demoTransactionId: existingTxn.isEmpty ? null : existingTxn,
            alreadyExisted: true,
          );
        }

        // 2. Read every product / bundle and work out the stock each order needs.
        final productSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        final bundleSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        final requiredStock = <String, int>{};
        final resolvedLines = <Map<String, dynamic>>[];

        Future<DocumentSnapshot<Map<String, dynamic>>> readProduct(String productId) async {
          final cached = productSnapshots[productId];
          if (cached != null) return cached;
          final snapshot = await transaction.get(products.doc(productId));
          productSnapshots[productId] = snapshot;
          return snapshot;
        }

        void addRequired(String productId, int quantity) {
          requiredStock[productId] = (requiredStock[productId] ?? 0) + quantity;
        }

        for (final line in items) {
          final quantity = _quantityValue(line['quantity']);
          if (quantity == null || quantity < 1 || quantity > 99) {
            fail('invalid-order', 'Each order quantity must be between 1 and 99.');
          }

          if (_cleanText(line['itemType']) == 'bundle') {
            final bundleId = _cleanText(line['bundleId']);
            if (bundleId.isEmpty || bundleId.contains('/')) {
              fail('invalid-order', 'A bundle in your bag is missing its ID.');
            }
            var bundleSnapshot = bundleSnapshots[bundleId];
            if (bundleSnapshot == null) {
              bundleSnapshot = await transaction.get(bundles.doc(bundleId));
              bundleSnapshots[bundleId] = bundleSnapshot;
            }
            if (!bundleSnapshot.exists) {
              fail('item-unavailable', 'A bundle in your bag is no longer available. Please refresh your bag.');
            }
            final bundleData = bundleSnapshot.data() ?? <String, dynamic>{};
            final rawIds = bundleData['productIds'];
            final productIds = rawIds is List
                ? rawIds.map(_cleanText).where((id) => id.isNotEmpty && !id.contains('/')).toList()
                : <String>[];
            final bundleName = _cleanText(bundleData['name'] ?? bundleData['title'] ?? 'This bundle');
            if (productIds.isEmpty) {
              fail('item-unavailable', '$bundleName has no included products configured.');
            }
            final bundlePrice = _numberValue(bundleData['price']);
            if (bundlePrice == null || !bundlePrice.isFinite || bundlePrice < 0) {
              fail('item-unavailable', 'This bundle has an invalid package price. Please contact the store admin.');
            }
            for (final productId in productIds) {
              addRequired(productId, quantity);
            }
            resolvedLines.add(<String, dynamic>{
              'itemType': 'bundle',
              'bundleId': bundleId,
              'bundleData': bundleData,
              'productIds': productIds,
              'quantity': quantity,
              'unitPrice': bundlePrice,
            });
          } else {
            final productId = _cleanText(line['productId']);
            if (productId.isEmpty || productId.contains('/')) {
              fail('invalid-order', 'A product in your bag is missing its ID.');
            }
            final snapshot = await readProduct(productId);
            if (!snapshot.exists) {
              fail('item-unavailable', 'A product in your bag is no longer available. Please refresh your bag.');
            }
            final productData = snapshot.data() ?? <String, dynamic>{};
            final price = _numberValue(productData['price']);
            if (price == null || !price.isFinite || price < 0) {
              fail('item-unavailable', '${_cleanText(productData['name'] ?? productId)} has an invalid price.');
            }
            addRequired(productId, quantity);
            resolvedLines.add(<String, dynamic>{
              'itemType': 'product',
              'productId': productId,
              'productData': productData,
              'quantity': quantity,
              'unitPrice': price,
            });
          }
        }

        // Load products that are only referenced inside bundles (all reads
        // must happen before the first write in a transaction).
        for (final productId in requiredStock.keys.toList()) {
          final snapshot = await readProduct(productId);
          if (!snapshot.exists) {
            fail('item-unavailable', 'A product included in your order is no longer available. Please refresh your bag.');
          }
        }

        // 3. Stock check: never sell more than is available, never go below 0.
        final nextStock = <String, int>{};
        requiredStock.forEach((productId, requestedQuantity) {
          final productData = productSnapshots[productId]!.data() ?? <String, dynamic>{};
          final available = _stockValue(productData);
          if (available < requestedQuantity) {
            final productName = _cleanText(productData['name'] ?? productId);
            fail(
              'out-of-stock',
              '$productName has only $available in stock, but your order needs '
                  '$requestedQuantity. Please update your bag and try again.',
            );
          }
          nextStock[productId] = available - requestedQuantity;
        });

        // 4. Build the order lines from the live Firestore prices.
        final orderItems = resolvedLines.map((line) {
          if (line['itemType'] == 'bundle') {
            final bundle = line['bundleData'] as Map<String, dynamic>;
            final productIds = (line['productIds'] as List<String>);
            return <String, dynamic>{
              'itemType': 'bundle',
              'bundleId': line['bundleId'],
              'name': _cleanText(bundle['name'] ?? bundle['title'] ?? 'Student Bundle'),
              'price': line['unitPrice'],
              'imageUrl': _cleanText(bundle['imageUrl'] ?? bundle['image']),
              'quantity': line['quantity'],
              'includedProductIds': productIds,
              'includedItems': productIds.map((productId) {
                final productData = productSnapshots[productId]!.data() ?? <String, dynamic>{};
                return <String, dynamic>{
                  'productId': productId,
                  'name': _cleanText(productData['name'] ?? productId),
                  'price': _numberValue(productData['price']) ?? 0,
                  'imageUrl': _cleanText(productData['imageUrl']),
                };
              }).toList(),
            };
          }
          final productData = line['productData'] as Map<String, dynamic>;
          return <String, dynamic>{
            'itemType': 'product',
            'productId': line['productId'],
            'name': _cleanText(productData['name'] ?? line['productId']),
            'price': line['unitPrice'],
            'imageUrl': _cleanText(productData['imageUrl']),
            'quantity': line['quantity'],
          };
        }).toList();

        final finalTotal = resolvedLines.fold<double>(
          0,
          (runningTotal, line) => runningTotal + (line['unitPrice'] as double) * (line['quantity'] as int),
        );
        if ((finalTotal - total).abs() > 0.01) {
          fail(
            'price-changed',
            'A product or bundle price changed while your bag was open. '
                'Please return to your bag and check the updated total.',
          );
        }

        // 5. Writes: stock decrements and the order commit together, or not at all.
        nextStock.forEach((productId, remaining) {
          transaction.update(products.doc(productId), <String, dynamic>{
            'stock': remaining,
            'lastOrderId': key,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });

        transaction.set(orderRef, <String, dynamic>{
          'orderKey': key,
          'userId': uid,
          'items': orderItems,
          'total': finalTotal,
          'status': 'pending',
          'paymentMethod': method,
          'paymentMode': paymentMode,
          'paymentStatus': paymentStatus,
          'demoTransactionId': ?demoTransactionId,
          'customerName': name,
          'customerPhone': phone,
          'customerEmail': _cleanText(user.email ?? customerEmail),
          'deliveryAddress': address,
          'deliveryCity': city,
          'deliveryPinCode': pinCode,
          'stockDeducted': true,
          'stockRestocked': false,
          // Exact quantity removed from each product; firestore.rules check it.
          'stockDeductions': requiredStock,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return OrderCreationResult(
          orderId: key,
          demoTransactionId: demoTransactionId,
        );
      });
    } catch (error, stackTrace) {
      // The real cause always goes to the debug console.
      debugPrint('createOrder($key) failed: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
      final ownError = checkError;
      if (ownError != null) throw ownError;
      if (error is OrderException) rethrow;
      throw OrderException.fromError(error);
    }
  }

  /// Admin-only: change an order's status. Cancelling puts the stock back;
  /// re-opening a cancelled order deducts it again (same rules as the old
  /// updateOrderStatus Cloud Function). firestore.rules allow this for admins.
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    const allowedStatuses = <String>{'pending', 'confirmed', 'shipped', 'delivered', 'cancelled'};
    final id = orderId.trim();
    final nextStatus = status.trim().toLowerCase();
    if (id.isEmpty || id.contains('/') || !allowedStatuses.contains(nextStatus)) {
      throw const OrderException('invalid-order', 'A valid order ID and status are required.');
    }

    OrderException? checkError;
    Never fail(String code, String message) {
      checkError = OrderException(code, message);
      throw checkError!;
    }

    final orderRef = orders.doc(id);
    try {
      await _db.runTransaction<void>((transaction) async {
        final orderSnapshot = await transaction.get(orderRef);
        if (!orderSnapshot.exists) fail('not-found', 'This order could not be found.');

        final orderData = orderSnapshot.data() ?? <String, dynamic>{};
        final currentStatus = _cleanText(orderData['status'] ?? 'pending').toLowerCase();
        final stockWasDeducted = orderData['stockDeducted'] == true;
        final wasRestocked = orderData['stockRestocked'] == true;
        final shouldRestock = stockWasDeducted && !wasRestocked &&
            currentStatus != 'cancelled' && nextStatus == 'cancelled';
        final shouldDeductAgain = stockWasDeducted && wasRestocked &&
            currentStatus == 'cancelled' && nextStatus != 'cancelled';

        final requirements = <String, int>{};
        if (shouldRestock || shouldDeductAgain) {
          final rawItems = orderData['items'];
          final orderItems = rawItems is List ? rawItems.whereType<Map>().toList() : <Map>[];
          for (final item in orderItems) {
            final quantity = _quantityValue(item['quantity']) ?? 0;
            if (quantity < 1) continue;
            if (_cleanText(item['itemType']) == 'bundle') {
              final rawIds = item['includedProductIds'];
              final ids = rawIds is List && rawIds.isNotEmpty
                  ? rawIds.map(_cleanText)
                  : (item['includedItems'] is List
                      ? (item['includedItems'] as List)
                          .whereType<Map>()
                          .map((entry) => _cleanText(entry['productId']))
                      : const Iterable<String>.empty());
              for (final productId in ids) {
                if (productId.isEmpty || productId.contains('/')) continue;
                requirements[productId] = (requirements[productId] ?? 0) + quantity;
              }
            } else {
              final productId = _cleanText(item['productId']);
              if (productId.isEmpty || productId.contains('/')) continue;
              requirements[productId] = (requirements[productId] ?? 0) + quantity;
            }
          }
        }

        final nextStock = <String, int>{};
        for (final entry in requirements.entries) {
          final snapshot = await transaction.get(products.doc(entry.key));
          if (!snapshot.exists) {
            if (shouldRestock) continue;
            fail('item-unavailable', 'A product from this order no longer exists, so the order cannot be reopened.');
          }
          final productData = snapshot.data() ?? <String, dynamic>{};
          final currentStock = _stockValue(productData);
          if (shouldDeductAgain && currentStock < entry.value) {
            fail(
              'out-of-stock',
              '${_cleanText(productData['name'] ?? entry.key)} has only $currentStock in stock. '
                  'There is not enough stock to reopen this order.',
            );
          }
          nextStock[entry.key] = shouldRestock ? currentStock + entry.value : currentStock - entry.value;
        }

        nextStock.forEach((productId, quantity) {
          transaction.update(products.doc(productId), <String, dynamic>{
            'stock': quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
        transaction.update(orderRef, <String, dynamic>{
          'status': nextStatus,
          'updatedAt': FieldValue.serverTimestamp(),
          if (shouldRestock) 'stockRestocked': true,
          if (shouldDeductAgain) 'stockRestocked': false,
        });
      });
    } catch (error, stackTrace) {
      debugPrint('updateOrderStatus($id -> $nextStatus) failed: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
      final ownError = checkError;
      if (ownError != null) throw ownError;
      if (error is OrderException) rethrow;
      throw OrderException.fromError(error);
    }
  }

  Future<void> createReview({
    required String uid,
    required String productId,
    required double rating,
    required String comment,
  }) {
    return reviews.add({
      'userId': uid,
      'productId': productId,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

