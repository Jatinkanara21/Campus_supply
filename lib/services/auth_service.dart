import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _loggedInKey = 'logged_in';
  static const _emailKey = 'user_email';
  static const _nameKey = 'user_name';
  static const _passwordKey = 'user_password';

  static Future<bool> register({required String name, required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
    await prefs.setString(_emailKey, email.trim().toLowerCase());
    await prefs.setString(_passwordKey, password);
    await prefs.setBool(_loggedInKey, true);
    return true;
  }

  static Future<bool> login({required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_emailKey);
    final savedPassword = prefs.getString(_passwordKey);
    if (savedEmail == null || savedPassword == null) return false;
    if (savedEmail != email.trim().toLowerCase() || savedPassword != password) return false;
    await prefs.setBool(_loggedInKey, true);
    return true;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<String> userName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? 'Student';
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
  }
}
