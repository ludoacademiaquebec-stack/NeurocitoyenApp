import 'package:shared_preferences/shared_preferences.dart';

class AuthGuard {
  static Future<bool> isLoggedIn() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') != null || prefs.getString('code_parrain') != null;
  }

  static Future<bool> isAdmin() async {
    var prefs = await SharedPreferences.getInstance();
    var role = prefs.getString('role');
    return role == 'mansa' || role == 'admin' || (prefs.getString('email')?.contains('admin') ?? false);
  }

  static Future<void> logout() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
