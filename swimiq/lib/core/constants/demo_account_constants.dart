/// Coach / demo login used for in-person team demos on swimiqapp.com.
///
/// Signing in loads a fully filled **Aspyn Briez** showcase profile so coaches
/// can see every tab with consistent athlete usage (PBs, meets, video feedback,
/// recruiting passport, goals, schedule, and more).
abstract final class DemoAccountConstants {
  static const email = 'demo@swimiqapp.com';

  /// Legacy Supabase `display_name` for the demo auth user.
  static const displayName = 'SwimIQ Demo';

  /// Athlete identity shown across the showcase demo.
  static const athleteName = 'Aspyn Briez';

  /// Demo password — change in Supabase Auth to match.
  static const password = 'SwimIQ';

  static bool isDemoEmail(String? email) {
    final value = email?.trim().toLowerCase();
    return value == DemoAccountConstants.email.toLowerCase();
  }

  static bool isDemoSwimmerKey(String? swimmerKey) {
    final key = swimmerKey?.trim().toLowerCase();
    if (key == null || key.isEmpty) return false;
    return key == athleteName.toLowerCase() ||
        key == displayName.toLowerCase() ||
        key == 'aspyn' ||
        key == 'aspyn briez williams';
  }
}
