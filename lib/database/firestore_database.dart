import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Result returned by the trusted order endpoint.
class OrderCreationResult {
  const OrderCreationResult({
    required this.orderId,
    this.demoTransactionId,
  });

  final String orderId;
  final String? demoTransactionId;
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

  static const String _placeOrderEndpoint =
      'https://us-central1-campus-supply-abcbf.cloudfunctions.net/placeOrder';
  static const String _updateOrderStatusEndpoint =
      'https://us-central1-campus-supply-abcbf.cloudfunctions.net/updateOrderStatus';

  Future<Map<String, dynamic>> _postAuthenticatedFunction(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please sign in before continuing.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Unable to verify your session. Please sign in again.');
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 60));

    Map<String, dynamic> payload = <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } catch (_) {
      // Use the HTTP status-based fallback below.
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = (payload['error'] ?? '').toString().trim();
      throw StateError(
        message.isNotEmpty
            ? message
            : 'The secure order service could not complete the request (HTTP ${response.statusCode}).',
      );
    }
    return payload;
  }

  Future<OrderCreationResult> createOrder({
    required String uid,
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
      throw StateError('Please sign in again before placing your order.');
    }

    final payload = await _postAuthenticatedFunction(_placeOrderEndpoint, {
      'items': items,
      'total': total,
      'paymentMethod': paymentMethod,
      'customerName': customerName.trim(),
      'customerPhone': customerPhone.trim(),
      'customerEmail': customerEmail.trim(),
      'deliveryAddress': deliveryAddress.trim(),
      'deliveryCity': deliveryCity.trim(),
      'deliveryPinCode': deliveryPinCode.trim(),
    });
    final orderId = (payload['orderId'] ?? '').toString().trim();
    if (orderId.isEmpty) {
      throw StateError('The order service did not return an order ID. Please check My Orders.');
    }
    final transactionId = (payload['demoTransactionId'] ?? '').toString().trim();
    return OrderCreationResult(
      orderId: orderId,
      demoTransactionId: transactionId.isEmpty ? null : transactionId,
    );
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _postAuthenticatedFunction(_updateOrderStatusEndpoint, {
      'orderId': orderId,
      'status': status,
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

