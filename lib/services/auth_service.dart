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

      try {
        await _db.collection('users').doc(user.uid).set({
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } on FirebaseException {
        // Authentication succeeded even if the profile document cannot
        // currently be written (for example before Firestore rules are deployed).
      }

      await _saveSession(
        email: user.email ?? email.trim().toLowerCase(),
        name: name.trim(),
      );
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

      var name = user.displayName ?? email.trim().split('@').first;

      // Do not block a successful Firebase Authentication login if the
      // Firestore profile is temporarily unavailable or rules are not deployed.
      try {
        final snapshot = await _db.collection('users').doc(user.uid).get();
        final data = snapshot.data();
        name = (data?['name'] as String?) ?? name;
      } on FirebaseException {
        // Keep the fallback name and continue the login flow.
      }

      await _saveSession(
        email: user.email ?? email.trim().toLowerCase(),
        name: name,
      );
      return true;
    } on FirebaseAuthException {
      return false;
    } on FirebaseException {
      return false;
    }
  }

  static Future<void> _saveSession({
    required String email,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', true);
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', name);
  }

  static Future<bool> isLoggedIn() async => _auth.currentUser != null;

  static Future<String> userName() async {
    final user = _auth.currentUser;
    if (user == null) return 'Student';

    try {
      final snapshot = await _db.collection('users').doc(user.uid).get();
      final data = snapshot.data();
      return (data?['name'] as String?) ?? user.displayName ?? 'Student';
    } on FirebaseException {
      return user.displayName ?? 'Student';
    }
  }

  static Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final snapshot = await _db.collection('users').doc(user.uid).get();
      final data = snapshot.data();
      return data?['role'] == 'admin' || data?['admin'] == true;
    } on FirebaseException {
      return false;
    }
  }

  static Future<String> role() async {
    final user = _auth.currentUser;
    if (user == null) return 'guest';

    try {
      final snapshot = await _db.collection('users').doc(user.uid).get();
      final data = snapshot.data();
      if (data?['admin'] == true) return 'admin';
      return (data?['role'] as String?) ?? 'user';
    } on FirebaseException {
      return 'user';
    }
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  static Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', false);
  }
}
