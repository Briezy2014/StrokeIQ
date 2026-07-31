import '../../data/models/personal_best_entry.dart';
import '../../data/models/swimmer_profile.dart';
import '../services/usa_motivational_standards_catalog.dart';
import '../utils/motivational_cut.dart';

/// One top-time row on the recruiting wallet card (per-event cut, not overall).
class RecruitingTopEvent {
  const RecruitingTopEvent({
    required this.line,
    this.cut,
  });

  /// e.g. "50 Butterfly  34.67"
  final String line;

  /// USA cut for this swim only: A, BB, … — never copy the athlete's best cut.
  final String? cut;

  static List<RecruitingTopEvent> fromPersonalBests({
    required List<PersonalBestEntry> personalBests,
    required UsaMotivationalStandardsCatalog catalog,
    required SwimmerProfile? profile,
    int limit = 3,
  }) {
    if (personalBests.isEmpty) return const [];
    return personalBests.take(limit).map((pb) {
      final cut = MotivationalCut.forSwim(
        catalog: catalog,
        profile: profile,
        stroke: pb.stroke,
        distance: pb.distance,
        course: pb.course,
        timeSeconds: pb.timeSeconds,
      );
      return RecruitingTopEvent(
        line: '${pb.displayTitle}  ${pb.formattedTime}',
        cut: _badgeCut(cut),
      );
    }).toList();
  }

  static List<String> linesOf(List<RecruitingTopEvent> events) =>
      events.map((e) => e.line).toList();

  static String? _badgeCut(String? cut) {
    if (cut == null) return null;
    final trimmed = cut.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase().contains('below')) return null;
    final match = RegExp(r'^(AAAA|AAA|AA|A|BB|B)$', caseSensitive: false)
        .firstMatch(trimmed);
    return match?.group(1)?.toUpperCase();
  }
}
