import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = credential.user;
      if (user == null) return false;
      await user.updateDisplayName(name.trim());
      await _db.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logged_in', true);
      await prefs.setString('user_email', email.trim().toLowerCase());
      await prefs.setString('user_name', name.trim());
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = credential.user;
      if (user == null) return false;
      final snapshot = await _db.collection('users').doc(user.uid).get();
      final data = snapshot.data();
      final name = (data?['name'] as String?) ??
          user.displayName ??
          email.trim().split('@').first;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logged_in', true);
      await prefs.setString('user_email', user.email ?? email.trim().toLowerCase());
      await prefs.setString('user_name', name);
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  static Future<bool> isLoggedIn() async => _auth.currentUser != null;

  static Future<String> userName() async {
    final user = _auth.currentUser;
    if (user == null) return 'Student';
    final snapshot = await _db.collection('users').doc(user.uid).get();
    final data = snapshot.data();
    return (data?['name'] as String?) ?? user.displayName ?? 'Student';
  }

  static Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final snapshot = await _db.collection('users').doc(user.uid).get();
    return snapshot.data()?['role'] == 'admin';
  }

  static Future<String> role() async {
    final user = _auth.currentUser;
    if (user == null) return 'guest';
    final snapshot = await _db.collection('users').doc(user.uid).get();
    return (snapshot.data()?['role'] as String?) ?? 'user';
  }

  static Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', false);
  }
}
