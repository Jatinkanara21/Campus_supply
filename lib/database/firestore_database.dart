import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Computes the product quantities consumed by an order.
  /// A bundle consumes each product in its includedProductIds for every bundle
  /// ordered. Duplicate product IDs count as multiple units per bundle.
  Map<String, int> _requiredStockQuantities(List<Map<String, dynamic>> items) {
    final required = <String, int>{};

    void addProduct(Object? rawId, int quantity) {
      final productId = (rawId ?? '').toString().trim();
      if (productId.isEmpty) {
        throw StateError('An order item is missing its product information. Please review your bag.');
      }
      required[productId] = (required[productId] ?? 0) + quantity;
    }

    for (final item in items) {
      final rawQuantity = item['quantity'];
      final quantity = rawQuantity is num
          ? rawQuantity.toInt()
          : int.tryParse((rawQuantity ?? '1').toString()) ?? 1;
      if (quantity < 1) {
        throw StateError('Order quantities must be at least one.');
      }

      final isBundle = (item['itemType'] ?? 'product').toString() == 'bundle';
      if (isBundle) {
        final rawIds = item['includedProductIds'];
        final rawIncludedItems = item['includedItems'];
        final includedIds = rawIds is List && rawIds.isNotEmpty
            ? rawIds
            : rawIncludedItems is List
                ? rawIncludedItems
                    .whereType<Map>()
                    .map((entry) => entry['productId'])
                    .where((id) => id != null)
                    .toList()
                : <dynamic>[];

        if (includedIds.isEmpty) {
          final bundleName = (item['name'] ?? 'Student bundle').toString();
          throw StateError('$bundleName has no included products configured.');
        }
        for (final productId in includedIds) {
          addProduct(productId, quantity);
        }
      } else {
        addProduct(item['productId'], quantity);
      }
    }

    if (required.isEmpty) {
      throw StateError('No valid products were found in this order.');
    }
    return required;
  }

  int _readStock(Map<String, dynamic>? productData) {
    final rawStock = productData?['stock'];
    if (rawStock is num) return rawStock.toInt();
    return int.tryParse((rawStock ?? '0').toString()) ?? 0;
  }

  Future<String> createOrder({
    required String uid,
    required List<Map<String, dynamic>> items,
    required double total,
    required String status,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryPinCode,
  }) async {
    final orderRef = orders.doc();
    final requiredStock = _requiredStockQuantities(items);

    // Stock updates and order creation are atomic. If any product has too
    // little stock, the order and all stock updates are rolled back.
    await _db.runTransaction((transaction) async {
      final productSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};

      // Read every product before writing anything in this transaction.
      for (final productId in requiredStock.keys) {
        productSnapshots[productId] = await transaction.get(products.doc(productId));
      }

      final nextStock = <String, int>{};
      for (final entry in requiredStock.entries) {
        final productId = entry.key;
        final snapshot = productSnapshots[productId]!;
        if (!snapshot.exists) {
          throw StateError('A product in your bag is no longer available. Please refresh your bag and try again.');
        }

        final productData = snapshot.data() ?? <String, dynamic>{};
        final available = _readStock(productData);
        final requested = entry.value;
        if (available < requested) {
          final productName = (productData['name'] ?? productId).toString();
          throw StateError(
            '$productName has only $available in stock, but your order needs $requested. '
            'Please update your bag and try again.',
          );
        }
        nextStock[productId] = available - requested;
      }

      for (final entry in nextStock.entries) {
        transaction.update(products.doc(entry.key), {
          'stock': entry.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(orderRef, {
        'userId': uid,
        'items': items,
        'total': total,
        'status': status,
        'customerName': customerName.trim(),
        'customerPhone': customerPhone.trim(),
        'customerEmail': customerEmail.trim(),
        'deliveryAddress': deliveryAddress.trim(),
        'deliveryCity': deliveryCity.trim(),
        'deliveryPinCode': deliveryPinCode.trim(),
        'stockDeducted': true,
        'stockRestocked': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return orderRef.id;
  }

  /// Updates the status and keeps stock consistent for cancellation/reopening.
  /// Only newly placed orders marked stockDeducted are adjusted; old historical
  /// orders therefore cannot accidentally increase the catalog stock.
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    const allowedStatuses = {'pending', 'confirmed', 'shipped', 'delivered', 'cancelled'};
    final nextStatus = status.toLowerCase().trim();
    if (!allowedStatuses.contains(nextStatus)) {
      throw ArgumentError.value(status, 'status', 'Unsupported order status.');
    }

    final orderRef = orders.doc(orderId);
    await _db.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      if (!orderSnapshot.exists) {
        throw StateError('This order could not be found.');
      }
      final orderData = orderSnapshot.data() ?? <String, dynamic>{};
      final currentStatus = (orderData['status'] ?? 'pending').toString().toLowerCase().trim();
      final stockWasDeducted = orderData['stockDeducted'] == true;
      final wasRestocked = orderData['stockRestocked'] == true;

      final shouldRestock = stockWasDeducted &&
          !wasRestocked &&
          currentStatus != 'cancelled' &&
          nextStatus == 'cancelled';
      final shouldDeductAgain = stockWasDeducted &&
          wasRestocked &&
          currentStatus == 'cancelled' &&
          nextStatus != 'cancelled';

      final requiredStock = (shouldRestock || shouldDeductAgain)
          ? _requiredStockQuantities(
              (orderData['items'] is List ? orderData['items'] as List : const <dynamic>[])
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList(),
            )
          : <String, int>{};

      final productSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final productId in requiredStock.keys) {
        productSnapshots[productId] = await transaction.get(products.doc(productId));
      }

      final nextStock = <String, int>{};
      for (final entry in requiredStock.entries) {
        final snapshot = productSnapshots[entry.key]!;
        if (!snapshot.exists) {
          if (shouldRestock) continue;
          throw StateError('A product from this order is no longer in the catalog; the order cannot be reopened.');
        }

        final productData = snapshot.data() ?? <String, dynamic>{};
        final currentStock = _readStock(productData);
        if (shouldDeductAgain && currentStock < entry.value) {
          final productName = (productData['name'] ?? entry.key).toString();
          throw StateError(
            '$productName has only $currentStock in stock. There is not enough stock to reopen this order.',
          );
        }
        nextStock[entry.key] = shouldRestock
            ? currentStock + entry.value
            : shouldDeductAgain
                ? currentStock - entry.value
                : currentStock;
      }

      for (final entry in nextStock.entries) {
        transaction.update(products.doc(entry.key), {
          'stock': entry.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(orderRef, {
        'status': nextStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (shouldRestock) 'stockRestocked': true,
        if (shouldDeductAgain) 'stockRestocked': false,
      });
    });
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

