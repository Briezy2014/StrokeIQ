import '../../core/utils/swim_event_parser.dart';
import '../../core/utils/swim_stroke_utils.dart';
import '../../core/utils/swim_time.dart';
import 'meet_result.dart';
import 'race_log.dart';

enum PersonalBestSource { session, meet }

class PersonalBestEntry {
  const PersonalBestEntry({
    required this.stroke,
    required this.distance,
    required this.course,
    required this.timeSeconds,
    required this.date,
    required this.eventLabel,
    required this.source,
    this.meetName,
  });

  final String stroke;
  final int distance;
  final String course;
  final double timeSeconds;
  final DateTime date;
  final String eventLabel;
  final PersonalBestSource source;
  final String? meetName;

  String get sourceLabel =>
      source == PersonalBestSource.meet ? 'Meet' : 'Session';

  String get eventKey => '$stroke|$distance|$course';

  String get displayTitle => '$distance $stroke';

  String get formattedTime => SwimTime.fromSeconds(timeSeconds);

  factory PersonalBestEntry.fromRaceLog(RaceLog log) {
    return PersonalBestEntry(
      stroke: SwimStrokeUtils.canonical(log.stroke),
      distance: log.distance,
      course: log.course,
      timeSeconds: log.timeSeconds,
      date: log.date,
      eventLabel: log.event,
      source: PersonalBestSource.session,
    );
  }

  factory PersonalBestEntry.fromMeetResult(MeetResult result) {
    final parts = SwimEventParser.parse(result.event);
    final stroke = parts != null
        ? parts.stroke
        : SwimStrokeUtils.canonical(result.event);
    final distance = parts?.distance ?? 0;

    return PersonalBestEntry(
      stroke: stroke,
      distance: distance,
      course: result.course,
      timeSeconds: result.swimTime,
      date: result.meetDate,
      eventLabel: result.event,
      source: PersonalBestSource.meet,
      meetName: result.meetName,
    );
  }

  bool get isValid => timeSeconds > 0 && distance > 0 && stroke.isNotEmpty;
}
