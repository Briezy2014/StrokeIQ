import 'package:shared_preferences/shared_preferences.dart';

/// Stores which ambassador referred this browser (for Stripe metadata / Rewardful).
abstract final class PendingAmbassadorReferralStorage {
  static const _key = 'pending_ambassador_referral_slug';

  static Future<void> save(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, slug.trim().toLowerCase());
  }

  static Future<String?> peek() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<String?> take() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) await prefs.remove(_key);
    return value;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
