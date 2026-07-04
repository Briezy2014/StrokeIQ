import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/swim_time.dart';

void main() {
  group('SwimTime', () {
    test('parses seconds-only format', () {
      expect(SwimTime.toSeconds('35.43'), 35.43);
    });

    test('parses minutes:seconds format', () {
      expect(SwimTime.toSeconds('1:24.32'), 84.32);
    });

    test('formats sub-minute times', () {
      expect(SwimTime.fromSeconds(35.43), '35.43');
    });

    test('formats minute times', () {
      expect(SwimTime.fromSeconds(84.32), '1:24.32');
    });

    test('rejects empty input', () {
      expect(() => SwimTime.toSeconds(''), throwsFormatException);
    });

    test('rejects multi-colon input', () {
      expect(() => SwimTime.toSeconds('1:02:03'), throwsFormatException);
    });

    test('isValid returns true for valid times', () {
      expect(SwimTime.isValid('1:24.32'), isTrue);
    });

    test('isValid returns false for invalid times', () {
      expect(SwimTime.isValid('abc'), isFalse);
    });
  });
}
