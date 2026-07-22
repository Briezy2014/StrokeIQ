import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/swim_event_options.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(loadTestMotivationalCatalog);

  group('SwimEventOptions', () {
    test('returns SCY events for a swimmer profile', () {
      final profile = SwimmerProfile(
        swimmerName: 'Aspyn',
        birthday: DateTime(2014, 3, 15),
        athleteNotes: 'Gender: Girls',
      );

      final options = SwimEventOptions.forProfile(
        catalog: testMotivationalCatalog,
        profile: profile,
        course: 'SCY',
      );

      expect(options, isNotEmpty);
      expect(options.any((option) => option.label == '400 IM'), isTrue);
      expect(options.every((option) => option.course == 'SCY'), isTrue);
    });

    test('includes 100 Butterfly for girls 11-12 SCY', () {
      final profile = SwimmerProfile(
        swimmerName: 'Test',
        birthday: DateTime(2014, 1, 1),
        athleteNotes: 'Gender: Girls',
      );

      final options = SwimEventOptions.forProfile(
        catalog: testMotivationalCatalog,
        profile: profile,
        course: 'SCY',
      );

      expect(
        options.any((option) => option.label == '100 Butterfly'),
        isTrue,
      );
    });
  });
}
