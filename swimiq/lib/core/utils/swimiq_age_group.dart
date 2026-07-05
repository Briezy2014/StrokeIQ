import '../../data/models/swimmer_profile.dart';

/// Shared USA Swimming age-group inference for standards and analysis.
class SwimIqAgeGroup {
  SwimIqAgeGroup._();

  static String fromProfile(SwimmerProfile? profile) {
    final age = profile?.age ?? _estimatedAgeFromGraduation(profile?.graduationYear);
    if (age == null) return '11-12';
    if (age <= 10) return '10 & under';
    if (age <= 12) return '11-12';
    if (age <= 14) return '13-14';
    if (age <= 16) return '15-16';
    if (age <= 18) return '17-18';
    return '17-18';
  }

  /// Estimates swimmer age when birthday is missing but graduation year is set.
  ///
  /// Uses class-of year minus 18 as an approximate birth year so swimmers like
  /// Aspyn (class of 2028) land in 13-14 / 15-16 instead of default 11-12.
  static int? _estimatedAgeFromGraduation(int? graduationYear) {
    if (graduationYear == null) return null;
    final today = DateTime.now();
    final estimatedBirthYear = graduationYear - 18;
    return today.year - estimatedBirthYear;
  }
}
