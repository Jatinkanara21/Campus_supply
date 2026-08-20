import 'database.dart';

Future<void> seedInitialData() async {
  final db = AppDatabase.instance;
  final existing = await db.products();
  if (existing.isNotEmpty) return;

  const products = [
    {'name': 'Campus Pro Backpack', 'description': 'Spacious water-resistant campus backpack with laptop sleeve.', 'price': 1499.0, 'category': 'Bags', 'image': '', 'color': 0xFFD38F62, 'stock': 25},
    {'name': 'Wireless Headphones', 'description': 'Comfortable wireless headphones for study and travel.', 'price': 1299.0, 'category': 'Electronics', 'image': '', 'color': 0xFF83B8D8, 'stock': 18},
    {'name': 'Premium Notebook', 'description': 'Premium ruled notebook for notes, planning and study.', 'price': 149.0, 'category': 'Stationery', 'image': '', 'color': 0xFFD6B26E, 'stock': 60},
    {'name': 'Steel Water Bottle', 'description': 'Reusable insulated steel bottle for everyday campus use.', 'price': 699.0, 'category': 'Essentials', 'image': '', 'color': 0xFFB7D88B, 'stock': 32},
    {'name': 'Scientific Calculator', 'description': 'Student-friendly scientific calculator for classes and labs.', 'price': 899.0, 'category': 'Electronics', 'image': '', 'color': 0xFF8FA7D8, 'stock': 14},
  ];

  for (final product in products) {
    await db.addProduct(product);
  }
}
