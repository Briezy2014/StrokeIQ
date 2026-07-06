import '../../data/models/swimmer_profile.dart';

/// Whether the athlete profile has enough data for accurate USA motivational cuts.
class SwimIqStandardsProfile {
  SwimIqStandardsProfile._();

  static bool isReady(SwimmerProfile? profile) {
    final gender = profile?.gender?.trim();
    return profile?.birthday != null && gender != null && gender.isNotEmpty;
  }

  static const setupMessage =
      'Add birthday and gender in Athlete Passport, then save, for accurate USA cuts.';

  static const setupMessageShort = 'Set birthday & gender in Passport';
}
