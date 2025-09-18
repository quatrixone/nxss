import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _keyBaseUrl = 'base_url';
  static const _keyToken = 'auth_token';

  static Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl);
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> setToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_keyToken);
    } else {
      await prefs.setString(_keyToken, token);
    }
  }
}


