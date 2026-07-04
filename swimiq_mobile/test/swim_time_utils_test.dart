import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq_mobile/core/swim_time_utils.dart';

void main() {
  group('SwimTimeUtils', () {
    test('parses seconds-only time', () {
      expect(SwimTimeUtils.swimTimeToSeconds('35.43'), 35.43);
    });

    test('parses minutes:seconds time', () {
      expect(SwimTimeUtils.swimTimeToSeconds('1:24.32'), 84.32);
    });

    test('formats seconds back to swim time', () {
      expect(SwimTimeUtils.secondsToSwimTime(35.43), '35.43');
      expect(SwimTimeUtils.secondsToSwimTime(84.32), '1:24.32');
    });
  });
}
