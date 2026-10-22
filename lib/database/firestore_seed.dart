import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Starter catalog for Campus Supply.
///
/// This function is intended to be called by an authenticated admin from the
/// Admin Dashboard. Firestore Security Rules remain the final authorization
/// layer, so normal users cannot seed or modify catalog data.
Future<int> seedStarterCatalog() async {
  final db = FirebaseFirestore.instance;
  final products = <String, Map<String, dynamic>>{
    'campus_pro_backpack': {
      'name': 'Campus Pro Backpack',
      'description': 'Spacious water-resistant campus backpack with laptop sleeve.',
      'price': 1499.0,
      'category': 'Bags',
      'imageUrl': '',
      'rating': 4.8,
      'stock': 25,
    },
    'wireless_headphones': {
      'name': 'Wireless Headphones',
      'description': 'Comfortable wireless headphones for study and travel.',
      'price': 1299.0,
      'category': 'Electronics',
      'imageUrl': '',
      'rating': 4.7,
      'stock': 18,
    },
    'premium_notebook': {
      'name': 'Premium Notebook',
      'description': 'Premium ruled notebook for notes, planning and study.',
      'price': 149.0,
      'category': 'Stationery',
      'imageUrl': '',
      'rating': 4.9,
      'stock': 60,
    },
    'steel_water_bottle': {
      'name': 'Steel Water Bottle',
      'description': 'Reusable insulated steel bottle for everyday campus use.',
      'price': 699.0,
      'category': 'Essentials',
      'imageUrl': '',
      'rating': 4.6,
      'stock': 32,
    },
    'scientific_calculator': {
      'name': 'Scientific Calculator',
      'description': 'Student-friendly scientific calculator for classes and labs.',
      'price': 899.0,
      'category': 'Electronics',
      'imageUrl': '',
      'rating': 4.8,
      'stock': 14,
    },
    'gel_pen_pack': {
      'name': 'Gel Pen Pack',
      'description': 'Smooth-writing gel pens for everyday class notes and assignments.',
      'price': 99.0,
      'category': 'Stationery',
      'imageUrl': '',
      'rating': 4.7,
      'stock': 80,
    },
    'study_table_lamp': {
      'name': 'Study Table Lamp',
      'description': 'Compact LED desk lamp for late-night study sessions.',
      'price': 799.0,
      'category': 'Study Essentials',
      'imageUrl': '',
      'rating': 4.5,
      'stock': 20,
    },
    'laptop_sleeve': {
      'name': 'Laptop Sleeve',
      'description': 'Slim protective sleeve for everyday laptop and college travel.',
      'price': 599.0,
      'category': 'Bags',
      'imageUrl': '',
      'rating': 4.6,
      'stock': 24,
    },
  };

  final categories = <String, Map<String, dynamic>>{
    'stationery': {
      'name': 'Stationery',
      'slug': 'stationery',
      'description': 'Pens, notebooks and everyday writing essentials.',
    },
    'bags': {
      'name': 'Bags',
      'slug': 'bags',
      'description': 'Backpacks, laptop sleeves and campus carry essentials.',
    },
    'electronics': {
      'name': 'Electronics',
      'slug': 'electronics',
      'description': 'Student-friendly electronics for study and campus life.',
    },
    'essentials': {
      'name': 'Essentials',
      'slug': 'essentials',
      'description': 'Reusable and practical everyday campus essentials.',
    },
    'study_essentials': {
      'name': 'Study Essentials',
      'slug': 'study-essentials',
      'description': 'Useful tools that make study sessions easier.',
    },
  };

  final bundles = <String, Map<String, dynamic>>{
    'exam_ready_kit': {
      'name': 'Exam Ready Kit',
      'badge': 'BEST FOR EXAMS',
      'description': 'Notebook, gel pens and a scientific calculator for exam preparation.',
      'price': 1099.0,
      'productIds': ['premium_notebook', 'gel_pen_pack', 'scientific_calculator'],
    },
    'campus_daily_kit': {
      'name': 'Campus Daily Kit',
      'badge': 'STUDENT PICK',
      'description': 'A practical backpack, bottle and notebook combination for daily classes.',
      'price': 1999.0,
      'productIds': ['campus_pro_backpack', 'steel_water_bottle', 'premium_notebook'],
    },
    'study_setup_kit': {
      'name': 'Study Setup Kit',
      'badge': 'STUDY SMART',
      'description': 'Simple essentials for a focused desk and productive study session.',
      'price': 1299.0,
      'productIds': ['study_table_lamp', 'premium_notebook', 'gel_pen_pack'],
    },
  };

  final refs = <DocumentReference<Map<String, dynamic>>>[
    ...products.keys.map((id) => db.collection('products').doc(id)),
    ...categories.keys.map((id) => db.collection('categories').doc(id)),
    ...bundles.keys.map((id) => db.collection('bundles').doc(id)),
  ];

  final snapshots = await Future.wait(refs.map((ref) => ref.get()));
  final batch = db.batch();
  var added = 0;
  var index = 0;

  void addMissing(
    CollectionReference<Map<String, dynamic>> collection,
    Map<String, Map<String, dynamic>> source,
  ) {
    for (final entry in source.entries) {
      final snapshot = snapshots[index++];
      if (snapshot.exists) continue;
      batch.set(collection.doc(entry.key), {
        ...entry.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      added++;
    }
  }

  addMissing(db.collection('products'), products);
  addMissing(db.collection('categories'), categories);
  addMissing(db.collection('bundles'), bundles);

  if (added > 0) await batch.commit();
  return added;
}


/// A dedicated login account intended only for faculty demonstrations.
class FacultyDemoAccount {
  const FacultyDemoAccount({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}

/// Counts created records so an admin can verify the demo-data run.
class FacultyDemoSeedSummary {
  const FacultyDemoSeedSummary({
    required this.accountsCreated,
    required this.accountsReused,
    required this.profilesCreated,
    required this.ordersCreated,
    required this.cartEntriesCreated,
    required this.wishlistEntriesCreated,
    required this.catalogRecordsAdded,
    required this.accounts,
  });

  final int accountsCreated;
  final int accountsReused;
  final int profilesCreated;
  final int ordersCreated;
  final int cartEntriesCreated;
  final int wishlistEntriesCreated;
  final int catalogRecordsAdded;
  final List<FacultyDemoAccount> accounts;
}

const _facultyDemoBatch = 'faculty_demo_v1';
const _facultyDemoPassword = 'CampusDemo@2026';

const _facultyDemoPeople = <Map<String, String>>[
  {
    'key': 'student01',
    'name': 'Riya Patel',
    'email': 'demo.student01@campus-supply.test',
    'phone': '0000000001',
    'address': 'Demo Address 01, Sample Street, Ahmedabad',
    'pin': '000000',
  },
  {
    'key': 'student02',
    'name': 'Aarav Shah',
    'email': 'demo.student02@campus-supply.test',
    'phone': '0000000002',
    'address': 'Demo Address 02, Sample Street, Ahmedabad',
    'pin': '000000',
  },
  {
    'key': 'student03',
    'name': 'Meera Desai',
    'email': 'demo.student03@campus-supply.test',
    'phone': '0000000003',
    'address': 'Demo Address 03, Sample Street, Ahmedabad',
    'pin': '000000',
  },
  {
    'key': 'student04',
    'name': 'Kunal Trivedi',
    'email': 'demo.student04@campus-supply.test',
    'phone': '0000000004',
    'address': 'Demo Address 04, Sample Street, Ahmedabad',
    'pin': '000000',
  },
  {
    'key': 'student05',
    'name': 'Nisha Joshi',
    'email': 'demo.student05@campus-supply.test',
    'phone': '0000000005',
    'address': 'Demo Address 05, Sample Street, Ahmedabad',
    'pin': '000000',
  },
];

/// Seeds dedicated Firebase Authentication demo accounts and their private data.
///
/// Safe to run again: only missing records in this demo batch are added.
/// Existing non-demo user, cart, wishlist, or order records are never replaced.
/// Must be called while an administrator is signed in.
Future<FacultyDemoSeedSummary> seedFacultyDemoData() async {
  final adminUser = FirebaseAuth.instance.currentUser;
  if (adminUser == null) {
    throw StateError('Sign in with the admin account before creating demo data.');
  }

  final primaryDb = FirebaseFirestore.instance;
  final adminProfile = await primaryDb.collection('users').doc(adminUser.uid).get();
  final adminRole = (adminProfile.data()?['role'] ?? '').toString().toLowerCase();
  if (adminRole != 'admin' && adminProfile.data()?['admin'] != true) {
    throw StateError('Only an administrator can create faculty demo data.');
  }

  // This catalog helper inserts only missing catalog documents.
  final catalogRecordsAdded = await seedStarterCatalog();

  // Fill missing product links for canonical starter bundles while preserving
  // any selection already configured by an administrator.
  const starterBundleLinks = <String, List<String>>{
    'exam_ready_kit': ['premium_notebook', 'gel_pen_pack', 'scientific_calculator'],
    'campus_daily_kit': ['campus_pro_backpack', 'steel_water_bottle', 'premium_notebook'],
    'study_setup_kit': ['study_table_lamp', 'premium_notebook', 'gel_pen_pack'],
  };
  for (final entry in starterBundleLinks.entries) {
    final ref = primaryDb.collection('bundles').doc(entry.key);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      throw StateError('Starter bundle ' + entry.key + ' could not be prepared.');
    }
    final currentIds = snapshot.data()?['productIds'];
    if (currentIds is! List || currentIds.isEmpty) {
      await ref.set({
        'productIds': entry.value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  final productSnapshot = await primaryDb.collection('products').get();
  final productsById = <String, Map<String, dynamic>>{
    for (final doc in productSnapshot.docs) doc.id: {'id': doc.id, ...doc.data()},
  };
  final bundleSnapshot = await primaryDb.collection('bundles').get();
  final bundlesById = <String, Map<String, dynamic>>{
    for (final doc in bundleSnapshot.docs) doc.id: {'id': doc.id, ...doc.data()},
  };

  double priceOf(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  Map<String, dynamic> productLine(String productId, {int quantity = 1}) {
    final product = productsById[productId];
    if (product == null) {
      throw StateError('Required demo product ' + productId + ' was not found.');
    }
    return <String, dynamic>{
      'itemType': 'product',
      'productId': productId,
      'name': (product['name'] ?? productId).toString(),
      'price': priceOf(product['price']),
      'imageUrl': (product['imageUrl'] ?? '').toString(),
      'quantity': quantity,
    };
  }

  Map<String, dynamic> bundleCartLine(String bundleId, {int quantity = 1}) {
    final bundle = bundlesById[bundleId];
    if (bundle == null) {
      throw StateError('Required demo bundle ' + bundleId + ' was not found.');
    }
    final rawIds = bundle['productIds'];
    final productIds = rawIds is List
        ? rawIds.map((value) => value.toString()).where((value) => value.trim().isNotEmpty).toList()
        : <String>[];
    if (productIds.isEmpty) {
      throw StateError('Demo bundle ' + bundleId + ' has no included products configured.');
    }
    final fallbackPrice = <String, double>{
      'exam_ready_kit': 1099,
      'campus_daily_kit': 1999,
      'study_setup_kit': 1299,
    }[bundleId] ?? 0;
    final currentPrice = priceOf(bundle['price']);
    final bundlePrice = currentPrice > 0 ? currentPrice : fallbackPrice;
    final includedItems = productIds.map((id) {
      final product = productsById[id] ?? <String, dynamic>{};
      return <String, dynamic>{
        'productId': id,
        'name': (product['name'] ?? id).toString(),
        'price': priceOf(product['price']),
        'imageUrl': (product['imageUrl'] ?? '').toString(),
      };
    }).toList();
    return <String, dynamic>{
      'itemType': 'bundle',
      'bundleId': bundleId,
      'bundleName': (bundle['name'] ?? bundle['title'] ?? 'Student Bundle').toString(),
      'bundleDescription': (bundle['description'] ?? '').toString(),
      'bundlePrice': bundlePrice,
      'bundleImageUrl': (bundle['imageUrl'] ?? bundle['image'] ?? '').toString(),
      'includedProductIds': productIds,
      'includedItems': includedItems,
      'quantity': quantity,
    };
  }

  Map<String, dynamic> orderLine(Map<String, dynamic> line) {
    if ((line['itemType'] ?? '').toString() == 'bundle') {
      return <String, dynamic>{
        'itemType': 'bundle',
        'bundleId': line['bundleId'],
        'name': line['bundleName'] ?? 'Student Bundle',
        'price': line['bundlePrice'] ?? 0,
        'imageUrl': line['bundleImageUrl'] ?? '',
        'quantity': line['quantity'] ?? 1,
        'includedProductIds': line['includedProductIds'] ?? <String>[],
        'includedItems': line['includedItems'] ?? <Map<String, dynamic>>[],
      };
    }
    return <String, dynamic>{
      'itemType': 'product',
      'productId': line['productId'],
      'name': line['name'] ?? 'Product',
      'price': line['price'] ?? 0,
      'imageUrl': line['imageUrl'] ?? '',
      'quantity': line['quantity'] ?? 1,
    };
  }

  double orderTotal(List<Map<String, dynamic>> lines) {
    return lines.fold<double>(0, (sum, line) {
      final isBundle = (line['itemType'] ?? '').toString() == 'bundle';
      final unitPrice = isBundle ? priceOf(line['bundlePrice']) : priceOf(line['price']);
      final quantity = line['quantity'] is num ? (line['quantity'] as num).toInt() : 1;
      return sum + unitPrice * quantity;
    });
  }

  const appName = 'campus-supply-faculty-demo-seed';
  final appAlreadyExists = Firebase.apps.any((app) => app.name == appName);
  final demoApp = appAlreadyExists
      ? Firebase.app(appName)
      : await Firebase.initializeApp(
          name: appName,
          options: DefaultFirebaseOptions.currentPlatform,
        );
  final demoAuth = FirebaseAuth.instanceFor(app: demoApp);
  final demoDb = FirebaseFirestore.instanceFor(app: demoApp);

  var accountsCreated = 0;
  var accountsReused = 0;
  var profilesCreated = 0;
  var ordersCreated = 0;
  var cartEntriesCreated = 0;
  var wishlistEntriesCreated = 0;

  try {
    await demoAuth.signOut();

    for (final person in _facultyDemoPeople) {
      final email = person['email']!;
      final name = person['name']!;
      UserCredential credential;
      var accountCreated = false;

      try {
        credential = await demoAuth.createUserWithEmailAndPassword(
          email: email,
          password: _facultyDemoPassword,
        );
        accountCreated = true;
        await credential.user?.updateDisplayName(name);
      } on FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') rethrow;
        try {
          credential = await demoAuth.signInWithEmailAndPassword(
            email: email,
            password: _facultyDemoPassword,
          );
        } on FirebaseAuthException {
          throw StateError(
            'The demo login ' + email + ' already exists with a different password. '
            'It was not changed. Please review that Firebase Auth account manually.',
          );
        }
      }

      final user = credential.user;
      if (user == null) {
        throw StateError('Firebase Authentication did not return a user for ' + email + '.');
      }
      if (accountCreated) {
        accountsCreated++;
      } else {
        accountsReused++;
      }

      final userRef = demoDb.collection('users').doc(user.uid);
      final userSnapshot = await userRef.get();
      final userData = userSnapshot.data();
      if (userSnapshot.exists && userData?['isDemo'] != true) {
        throw StateError(
          'The profile for ' + email + ' already contains non-demo data. '
          'To avoid overwriting it, seeding was stopped.',
        );
      }
      final profile = <String, dynamic>{
        'name': name,
        'email': email,
        'role': 'user',
        'isDemo': true,
        'demoBatch': _facultyDemoBatch,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!userSnapshot.exists) {
        profile['createdAt'] = FieldValue.serverTimestamp();
        profilesCreated++;
      }
      await userRef.set(profile, SetOptions(merge: true));

      final uid = user.uid;
      final cartLines = <Map<String, dynamic>>[
        productLine('campus_pro_backpack'),
        productLine('premium_notebook', quantity: 2),
        bundleCartLine('study_setup_kit'),
      ];
      final cartSnapshot = await demoDb.collection('carts').where('userId', isEqualTo: uid).get();
      final cartById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
        for (final doc in cartSnapshot.docs) doc.id: doc,
      };
      for (final line in cartLines) {
        final isBundle = (line['itemType'] ?? '').toString() == 'bundle';
        final itemId = isBundle ? line['bundleId'].toString() : line['productId'].toString();
        final cartId = isBundle ? uid + '_bundle_' + itemId : uid + '_' + itemId;
        final existing = cartById[cartId];
        if (existing != null) {
          if (existing.data()['isDemo'] != true) {
            throw StateError('A non-demo cart row exists for ' + email + '. It was not changed.');
          }
          continue;
        }
        await demoDb.collection('carts').doc(cartId).set({
          ...line,
          'userId': uid,
          'isDemo': true,
          'demoBatch': _facultyDemoBatch,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        cartEntriesCreated++;
      }

      const wishlistProductIds = [
        'premium_notebook',
        'steel_water_bottle',
        'scientific_calculator',
      ];
      final wishlistSnapshot = await demoDb.collection('wishlists').where('userId', isEqualTo: uid).get();
      final wishlistById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
        for (final doc in wishlistSnapshot.docs) doc.id: doc,
      };
      for (final productId in wishlistProductIds) {
        final wishlistId = uid + '_' + productId;
        final existing = wishlistById[wishlistId];
        if (existing != null) {
          if (existing.data()['isDemo'] != true) {
            throw StateError('A non-demo wishlist row exists for ' + email + '. It was not changed.');
          }
          continue;
        }
        await demoDb.collection('wishlists').doc(wishlistId).set({
          'userId': uid,
          'productId': productId,
          'isDemo': true,
          'demoBatch': _facultyDemoBatch,
          'createdAt': FieldValue.serverTimestamp(),
        });
        wishlistEntriesCreated++;
      }

      final existingOrdersSnapshot = await demoDb.collection('orders').where('userId', isEqualTo: uid).get();
      final existingOrders = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
        for (final doc in existingOrdersSnapshot.docs) doc.id: doc,
      };
      final now = DateTime.now();
      final orderTemplates = <Map<String, dynamic>>[
        {
          'status': 'pending',
          'ageHours': 2,
          'lines': <Map<String, dynamic>>[productLine('campus_pro_backpack')],
        },
        {
          'status': 'confirmed',
          'ageHours': 30,
          'lines': <Map<String, dynamic>>[
            productLine('premium_notebook', quantity: 2),
            productLine('gel_pen_pack'),
          ],
        },
        {
          'status': 'shipped',
          'ageHours': 54,
          'lines': <Map<String, dynamic>>[bundleCartLine('exam_ready_kit')],
        },
        {
          'status': 'delivered',
          'ageHours': 216,
          'lines': <Map<String, dynamic>>[productLine('steel_water_bottle')],
        },
        {
          'status': 'cancelled',
          'ageHours': 102,
          'lines': <Map<String, dynamic>>[bundleCartLine('campus_daily_kit')],
        },
      ];

      for (final template in orderTemplates) {
        final status = template['status'].toString();
        final orderId = 'faculty_demo_' + uid + '_order_' + status;
        final existing = existingOrders[orderId];
        if (existing != null) {
          if (existing.data()['isDemo'] != true) {
            throw StateError('A non-demo order row exists for ' + email + '. It was not changed.');
          }
          continue;
        }

        final lines = (template['lines'] as List<Map<String, dynamic>>)
            .map(orderLine)
            .toList();
        final createdAt = now.subtract(Duration(hours: template['ageHours'] as int));
        final orderTimestamp = Timestamp.fromDate(createdAt);
        await demoDb.collection('orders').doc(orderId).set({
          'userId': uid,
          'items': lines,
          'total': orderTotal(template['lines'] as List<Map<String, dynamic>>),
          'status': status,
          'customerName': name,
          'customerPhone': person['phone']!,
          'customerEmail': email,
          'deliveryAddress': person['address']! + ' (SAMPLE ONLY)',
          'deliveryCity': 'Ahmedabad',
          'deliveryPinCode': person['pin']!,
          'isDemo': true,
          'demoBatch': _facultyDemoBatch,
          'createdAt': orderTimestamp,
          'updatedAt': orderTimestamp,
        });
        ordersCreated++;
      }
    }
  } finally {
    try {
      await demoAuth.signOut();
    } catch (_) {
      // Do not affect the primary admin session if cleanup is unavailable.
    }
    try {
      await demoApp.delete();
    } catch (_) {
      // The dedicated secondary app is no longer needed after seeding.
    }
  }

  return FacultyDemoSeedSummary(
    accountsCreated: accountsCreated,
    accountsReused: accountsReused,
    profilesCreated: profilesCreated,
    ordersCreated: ordersCreated,
    cartEntriesCreated: cartEntriesCreated,
    wishlistEntriesCreated: wishlistEntriesCreated,
    catalogRecordsAdded: catalogRecordsAdded,
    accounts: [
      for (final person in _facultyDemoPeople)
        FacultyDemoAccount(
          name: person['name']!,
          email: person['email']!,
          password: _facultyDemoPassword,
        ),
    ],
  );
}
