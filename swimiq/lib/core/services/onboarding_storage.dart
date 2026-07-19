import 'package:shared_preferences/shared_preferences.dart';

/// Persists first-launch onboarding completion on device.
class OnboardingStorage {
  OnboardingStorage._();

  static const _completedKey = 'swimiq_onboarding_completed_v1';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  /// Clears completion so the walkthrough can be tested again.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
  }
}
