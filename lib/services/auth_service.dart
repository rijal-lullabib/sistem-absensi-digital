import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String adminUsername = 'admin';
  static const String adminPassword = 'jasakula123'; // Ganti dengan password yang lebih aman

  static Future<bool> login(String username, String password) async {
    if (username == adminUsername && password == adminPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }
}