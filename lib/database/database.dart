import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'campus_supply.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'user'
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            price REAL NOT NULL,
            category TEXT NOT NULL,
            image TEXT,
            color INTEGER,
            stock INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE wishlist (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL,
            productId INTEGER NOT NULL,
            UNIQUE(userId, productId)
          )
        ''');
        await db.execute('''
          CREATE TABLE cart (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL,
            productId INTEGER NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            UNIQUE(userId, productId)
          )
        ''');
      },
    );
  }

  Future<int> createUser({required String name, required String email, required String password, String role = 'user'}) async {
    final db = await database;
    return db.insert('users', {'name': name, 'email': email, 'password': password, 'role': role});
  }

  Future<Map<String, Object?>?> login(String email, String password) async {
    final db = await database;
    final rows = await db.query('users', where: 'email = ? AND password = ?', whereArgs: [email, password], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> addProduct(Map<String, Object?> product) async => (await database).insert('products', product);
  Future<List<Map<String, Object?>>> products() async => (await database).query('products', orderBy: 'id DESC');

  Future<void> toggleWishlist({required int userId, required int productId}) async {
    final db = await database;
    final rows = await db.query('wishlist', where: 'userId = ? AND productId = ?', whereArgs: [userId, productId], limit: 1);
    if (rows.isEmpty) {
      await db.insert('wishlist', {'userId': userId, 'productId': productId});
    } else {
      await db.delete('wishlist', where: 'userId = ? AND productId = ?', whereArgs: [userId, productId]);
    }
  }

  Future<List<Map<String, Object?>>> wishlist(int userId) async {
    final db = await database;
    return db.rawQuery('SELECT p.* FROM products p INNER JOIN wishlist w ON p.id = w.productId WHERE w.userId = ?', [userId]);
  }

  Future<void> addToCart({required int userId, required int productId, int quantity = 1}) async {
    final db = await database;
    await db.insert('cart', {'userId': userId, 'productId': productId, 'quantity': quantity}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
