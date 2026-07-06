import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/team_schedule_service.dart';
import 'package:swimiq/core/utils/passport_metrics.dart';
import 'package:swimiq/data/models/scheduled_meet.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';

void main() {
  group('ScheduledMeet.fromCoaTeamEvent', () {
    test('parses SportsEngine team event payload', () {
      final meet = ScheduledMeet.fromCoaTeamEvent({
        'id': {'value': 1737175},
        'title': {'value': 'Central Regional Championships'},
        'startDate': {'value': '2026-07-09T21:00:00.000-07:00'},
        'endDate': {'value': '2026-07-11T21:00:00.000-07:00'},
        'location': {'value': 'Steen Aquatic Center'},
        'categories': {'value': ['Swim Meet']},
      });

      expect(meet.externalId, '1737175');
      expect(meet.name, 'Central Regional Championships');
      expect(meet.startDate, DateTime(2026, 7, 9));
      expect(meet.location, 'Steen Aquatic Center');
      expect(meet.isSwimMeet, isTrue);
    });
  });

  group('TeamScheduleService.parseSyncResponse', () {
    test('maps edge function JSON to scheduled meets', () {
      final result = TeamScheduleService.parseSyncResponse({
        'team': 'Central Ohio Aquatics',
        'events': [
          {
            'id': {'value': 1},
            'title': {'value': 'Districts'},
            'startDate': {'value': '2026-08-01T12:00:00.000-04:00'},
            'categories': {'value': ['Swim Meet']},
          },
        ],
        'pdf_links': [
          {
            'label': 'Single-page SC Meet Schedule',
            'url': 'https://example.com/schedule.pdf',
            'updated': 'August 11, 2025',
          },
        ],
      });

      expect(result.teamName, 'Central Ohio Aquatics');
      expect(result.meets, hasLength(1));
      expect(result.meets.first.name, 'Districts');
      expect(result.pdfLinks, hasLength(1));
    });
  });

  group('PassportMetrics upcoming meet', () {
    test('prefers attending team meets over goals', () {
      final label = PassportMetrics.upcomingMeet(
        const [],
        attendingMeets: [
          ScheduledMeet(
            externalId: '1',
            name: 'Central Regional Championships',
            startDate: DateTime(2026, 7, 9),
            location: 'Gambier, OH',
            categories: const ['Swim Meet'],
          ),
        ],
      );

      expect(label, contains('Central Regional Championships'));
      expect(label, contains('7/9/2026'));
      expect(label, contains('Gambier'));
    });
  });

  group('SwimmerProfile attending meets', () {
    test('round-trips attending meet ids in athlete notes', () {
      final notes = SwimmerProfile.composeAthleteNotes(
        gender: 'Female',
        attendingMeetIds: const ['1737175', '1654383'],
      );
      final profile = SwimmerProfile(
        swimmerName: 'Aspyn',
        athleteNotes: notes,
      );

      expect(profile.attendingMeetIds, ['1737175', '1654383']);
    });
  });
}
