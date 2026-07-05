import '../../data/models/swimmer_profile.dart';

/// Shared USA Swimming age-group inference for standards and analysis.
class SwimIqAgeGroup {
  SwimIqAgeGroup._();

  /// Returns null when birthday is missing — do not guess an age bracket.
  static String? fromProfileOrNull(SwimmerProfile? profile) {
    final age = profile?.age;
    if (age == null) return null;
    return _bracketForAge(age);
  }

  /// Best-effort bracket for display when birthday is missing but graduation
  /// year is set. Do not use for motivational cuts — use [fromProfileOrNull].
  static String fromProfile(SwimmerProfile? profile) {
    final age =
        profile?.age ?? _estimatedAgeFromGraduation(profile?.graduationYear);
    if (age == null) return '11-12';
    return _bracketForAge(age);
  }

  static String _bracketForAge(int age) {
    if (age <= 10) return '10 & under';
    if (age <= 12) return '11-12';
    if (age <= 14) return '13-14';
    if (age <= 16) return '15-16';
    if (age <= 18) return '17-18';
    return '17-18';
  }

  /// Estimates swimmer age when birthday is missing but graduation year is set.
  static int? _estimatedAgeFromGraduation(int? graduationYear) {
    if (graduationYear == null) return null;
    final today = DateTime.now();
    final estimatedBirthYear = graduationYear - 18;
    return today.year - estimatedBirthYear;
  }
}
