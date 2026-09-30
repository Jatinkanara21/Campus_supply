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

  Stream<List<Map<String, dynamic>>> watchBundles() {
    return bundles.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  Future<void> updateCartQuantity({
    required String uid,
    required String productId,
    required int quantity,
  }) async {
    final ref = carts.doc('${uid}_${productId}');
    if (quantity <= 0) {
      await ref.delete();
      return;
    }
    await ref.set({
      'userId': uid,
      'productId': productId,
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeFromCart({
    required String uid,
    required String productId,
  }) => carts.doc('${uid}_${productId}').delete();

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
      'productId': productId,
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> watchCart(String uid) {
    return carts
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  Future<String> createOrder({
    required String uid,
    required List<Map<String, dynamic>> items,
    required double total,
    required String status,
  }) async {
    final ref = await orders.add({
      'userId': uid,
      'items': items,
      'total': total,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
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

