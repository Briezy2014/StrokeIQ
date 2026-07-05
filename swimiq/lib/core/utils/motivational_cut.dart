import '../../data/models/meet_result.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swimmer_profile.dart';
import '../services/usa_motivational_standards_catalog.dart';
import 'swimiq_age_group.dart';
import 'swimiq_gender.dart';

class MotivationalCut {
  MotivationalCut._();

  static String? forSwim({
    required UsaMotivationalStandardsCatalog catalog,
    required SwimmerProfile? profile,
    required String stroke,
    required int distance,
    required String course,
    required double timeSeconds,
  }) {
    return catalog.highestCutForTime(
      stroke: stroke,
      distance: distance,
      course: course,
      swimmerTime: timeSeconds,
      ageGroup: SwimIqAgeGroup.fromProfile(profile),
      gender: SwimIqGender.standardsGender(profile),
    );
  }

  static String labelForSwim({
    required UsaMotivationalStandardsCatalog catalog,
    required SwimmerProfile? profile,
    required String stroke,
    required int distance,
    required String course,
    required double timeSeconds,
  }) {
    return forSwim(
          catalog: catalog,
          profile: profile,
          stroke: stroke,
          distance: distance,
          course: course,
          timeSeconds: timeSeconds,
        ) ??
        'Below B';
  }

  static String? forRaceLog({
    required UsaMotivationalStandardsCatalog catalog,
    required SwimmerProfile? profile,
    required RaceLog log,
  }) =>
      forSwim(
        catalog: catalog,
        profile: profile,
        stroke: log.stroke,
        distance: log.distance,
        course: log.course,
        timeSeconds: log.timeSeconds,
      );

  static String? forMeetResult({
    required UsaMotivationalStandardsCatalog catalog,
    required SwimmerProfile? profile,
    required MeetResult result,
    required String stroke,
    required int distance,
  }) =>
      forSwim(
        catalog: catalog,
        profile: profile,
        stroke: stroke,
        distance: distance,
        course: result.course,
        timeSeconds: result.swimTime,
      );
}
