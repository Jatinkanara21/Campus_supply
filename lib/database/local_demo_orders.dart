import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Browser/device-local order history for demo-only payments.
/// These orders are not synced to Firestore or visible to other devices.
class LocalDemoOrders {
  LocalDemoOrders._();

  static const String _keyPrefix = 'campus_supply_local_demo_orders_';

  static String _keyFor(String uid) => '$_keyPrefix$uid';

  static Future<List<Map<String, dynamic>>> readForUser(String uid) async {
    if (uid.trim().isEmpty) return <Map<String, dynamic>>[];

    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_keyFor(uid));
    if (encoded == null || encoded.isEmpty) return <Map<String, dynamic>>[];

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return <Map<String, dynamic>>[];

      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> saveForUser(
    String uid,
    Map<String, dynamic> order,
  ) async {
    if (uid.trim().isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'A user ID is required.');
    }

    final preferences = await SharedPreferences.getInstance();
    final existing = await readForUser(uid);
    final orderId = (order['id'] ?? '').toString();

    existing.removeWhere((entry) => (entry['id'] ?? '').toString() == orderId);
    existing.insert(0, Map<String, dynamic>.from(order));

    // Keep local storage small for a student-project demo.
    if (existing.length > 50) {
      existing.removeRange(50, existing.length);
    }

    final saved = await preferences.setString(_keyFor(uid), jsonEncode(existing));
    if (!saved) {
      throw StateError('Could not save this demo order on this device.');
    }
  }
}
