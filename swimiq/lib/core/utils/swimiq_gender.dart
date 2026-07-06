import '../../data/models/swimmer_profile.dart';

class SwimIqGender {
  SwimIqGender._();

  /// Returns null when gender is missing — do not guess Girls/Boys.
  static String? standardsGenderOrNull(SwimmerProfile? profile) {
    final raw = profile?.gender?.trim();
    if (raw == null || raw.isEmpty) return null;
    final lower = raw.toLowerCase();
    if (lower.startsWith('m') || lower.startsWith('b')) return 'Boys';
    return 'Girls';
  }

  static String standardsGender(SwimmerProfile? profile) {
    return standardsGenderOrNull(profile) ?? 'Girls';
  }
}
