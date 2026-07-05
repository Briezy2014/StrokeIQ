import '../../data/models/swimmer_profile.dart';

/// Shared USA Swimming age-group inference for standards and analysis.
class SwimIqAgeGroup {
  SwimIqAgeGroup._();

  /// Returns null when birthday is missing — do not guess an age bracket.
  static String? fromProfileOrNull(SwimmerProfile? profile) {
    final age = profile?.age;
    if (age == null) return null;
    if (age <= 10) return '10 & under';
    if (age <= 12) return '11-12';
    if (age <= 14) return '13-14';
    if (age <= 16) return '15-16';
    if (age <= 18) return '17-18';
    return '17-18';
  }

  static String fromProfile(SwimmerProfile? profile) {
    return fromProfileOrNull(profile) ?? '11-12';
  }
}
