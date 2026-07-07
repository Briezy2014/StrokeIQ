import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/meet_schedule_scan_service.dart';
import 'package:swimiq/data/models/scheduled_meet.dart';

void main() {
  group('ScheduledMeet.fromScanJson', () {
    test('parses Gemini meet payload', () {
      final meet = ScheduledMeet.fromScanJson({
        'name': 'District Championships',
        'start_date': '2026-08-15',
        'location': 'Columbus, OH',
        'course': 'SCY',
      });

      expect(meet.name, 'District Championships');
      expect(meet.startDate, DateTime(2026, 8, 15));
      expect(meet.location, 'Columbus, OH');
      expect(meet.course, 'SCY');
      expect(meet.source, 'photo-scan');
    });
  });

  group('MeetScheduleScanService.parseMeetsResponse', () {
    test('filters past meets and sorts upcoming', () {
      final meets = MeetScheduleScanService.parseMeetsResponse({
        'meets': [
          {
            'name': 'Past Invite',
            'start_date': '2020-01-01',
          },
          {
            'name': 'Future Invite',
            'start_date': '2099-06-01',
          },
        ],
      });

      expect(meets, hasLength(1));
      expect(meets.first.name, 'Future Invite');
    });
  });

  group('ScheduledMeet encode/decode', () {
    test('round-trips through profile JSON line', () {
      final original = [
        ScheduledMeet(
          externalId: '1',
          name: 'Sectionals',
          startDate: DateTime(2026, 7, 15),
          location: 'OSU',
        ),
      ];
      final encoded = ScheduledMeet.encodeList(original);
      final decoded = ScheduledMeet.decodeList(encoded);
      expect(decoded.first.name, 'Sectionals');
      expect(decoded.first.location, 'OSU');
    });
  });
}
