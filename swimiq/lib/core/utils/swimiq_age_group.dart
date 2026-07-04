import '../../data/models/swimmer_profile.dart';

/// Shared USA Swimming age-group inference for standards and analysis.
class SwimIqAgeGroup {
  SwimIqAgeGroup._();

  static String fromProfile(SwimmerProfile? profile) {
    final age = profile?.age;
    if (age == null) return '11-12';
    if (age <= 10) return '10 & Under';
    if (age <= 12) return '11-12';
    if (age <= 14) return '13-14';
    return '15-16';
  }
}
