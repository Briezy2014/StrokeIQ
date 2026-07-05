import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/swimiq_age_group.dart';
import 'package:swimiq/core/utils/swimiq_gender.dart';
import 'package:swimiq/core/utils/swimiq_standards_profile.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';

void main() {
  group('SwimIqStandardsProfile', () {
    test('is not ready without birthday', () {
      final profile = SwimmerProfile(
        swimmerName: 'Aspyn',
        athleteNotes: SwimmerProfile.composeAthleteNotes(gender: 'Female'),
      );

      expect(SwimIqStandardsProfile.isReady(profile), isFalse);
      expect(SwimIqAgeGroup.fromProfileOrNull(profile), isNull);
      expect(SwimIqGender.standardsGenderOrNull(profile), 'Girls');
    });

    test('is not ready without gender', () {
      final profile = SwimmerProfile(
        swimmerName: 'Aspyn',
        birthday: DateTime(2014, 1, 1),
      );

      expect(SwimIqStandardsProfile.isReady(profile), isFalse);
      expect(SwimIqGender.standardsGenderOrNull(profile), isNull);
      expect(SwimIqAgeGroup.fromProfileOrNull(profile), '11-12');
    });

    test('is ready with birthday and gender', () {
      final profile = SwimmerProfile(
        swimmerName: 'Aspyn',
        birthday: DateTime(2014, 1, 1),
        athleteNotes: SwimmerProfile.composeAthleteNotes(gender: 'Female'),
      );

      expect(SwimIqStandardsProfile.isReady(profile), isTrue);
      expect(SwimIqAgeGroup.fromProfileOrNull(profile), '11-12');
      expect(SwimIqGender.standardsGenderOrNull(profile), 'Girls');
    });
  });
}
