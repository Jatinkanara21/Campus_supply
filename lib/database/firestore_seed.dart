import 'package:cloud_firestore/cloud_firestore.dart';

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
