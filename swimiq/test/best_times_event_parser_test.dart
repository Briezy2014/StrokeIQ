import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/best_times_event_parser.dart';
import 'package:swimiq/core/utils/swim_event_options.dart';

void main() {
  group('BestTimesEventParser', () {
    test('normalizes course letters from Best Times History', () {
      expect(BestTimesEventParser.normalizeCourse('Y'), 'SCY');
      expect(BestTimesEventParser.normalizeCourse('L'), 'LCM');
      expect(BestTimesEventParser.normalizeCourse('SCY'), 'SCY');
      expect(BestTimesEventParser.normalizeCourse('LONG COURSE METERS'), 'LCM');
    });

    test('parses event shorthand used by TeamUnify screenshots', () {
      expect(
        BestTimesEventParser.parseEventParts('50 Fly'),
        (distance: 50, stroke: 'Butterfly'),
      );
      expect(
        BestTimesEventParser.parseEventParts('100 Back'),
        (distance: 100, stroke: 'Backstroke'),
      );
      expect(
        BestTimesEventParser.parseEventParts('400 IM'),
        (distance: 400, stroke: 'IM'),
      );
      expect(
        BestTimesEventParser.parseEventParts('500 Free'),
        (distance: 500, stroke: 'Freestyle'),
      );
    });

    test('parses times with Y/L suffixes', () {
      expect(BestTimesEventParser.parseTimeSeconds('31.60 Y'), 31.60);
      expect(BestTimesEventParser.parseTimeSeconds('1:12.05Y'), closeTo(72.05, 0.001));
      expect(BestTimesEventParser.parseTimeSeconds('6:26.62 L'), closeTo(386.62, 0.001));
    });

    test('matches options for SCY fly', () {
      const options = [
        SwimEventOption(
          distance: 50,
          stroke: 'Butterfly',
          course: 'SCY',
          label: '50 Butterfly',
        ),
        SwimEventOption(
          distance: 100,
          stroke: 'Butterfly',
          course: 'SCY',
          label: '100 Butterfly',
        ),
      ];
      final matched = BestTimesEventParser.matchOption(
        eventRaw: '50 Fly',
        course: 'SCY',
        options: options,
      );
      expect(matched?.label, '50 Butterfly');
      expect(matched?.course, 'SCY');
    });

    test('parses MM/DD/YYYY dates', () {
      expect(
        BestTimesEventParser.parseDate('03/01/2026'),
        DateTime(2026, 3, 1),
      );
    });
  });
}
