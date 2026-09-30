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
    return products
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
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
