import 'package:shared_preferences/shared_preferences.dart';

/// Holds a validated coach code between login/signup and subscription redeem.
abstract final class PendingCoachCodeStorage {
  static const _key = 'pending_coach_access_code';

  static Future<void> save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code.trim().toUpperCase());
  }

  static Future<String?> peek() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  /// Returns stored code and clears it (call once after redeem).
  static Future<String?> take() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      await prefs.remove(_key);
    }
    return code;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
