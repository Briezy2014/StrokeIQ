import '../../core/utils/swim_time.dart';

/// One event row from the 2024-2028 USA Swimming motivational standards.
class UsaMotivationalEventStandard {
  const UsaMotivationalEventStandard({
    required this.versionId,
    required this.ageGroup,
    required this.gender,
    required this.course,
    required this.distance,
    required this.stroke,
    required this.event,
    required this.cuts,
  });

  final String versionId;
  final String ageGroup;
  final String gender;
  final String course;
  final int distance;
  final String stroke;
  final String event;
  final Map<String, double> cuts;

  double? cutFor(String level) => cuts[level];

  factory UsaMotivationalEventStandard.fromJson(Map<String, dynamic> json) {
    final cutsJson = Map<String, dynamic>.from(json['cuts'] as Map? ?? {});
    final cuts = <String, double>{};
    for (final entry in cutsJson.entries) {
      final value = SwimTime.parseStoredTime(entry.value);
      if (value != null) cuts[entry.key] = value;
    }

    return UsaMotivationalEventStandard(
      versionId: json['version'] as String? ?? '',
      ageGroup: json['age_group'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      course: json['course'] as String? ?? '',
      distance: (json['distance'] as num?)?.toInt() ?? 0,
      stroke: json['stroke'] as String? ?? '',
      event: json['event'] as String? ?? '',
      cuts: cuts,
    );
  }
}

class UsaMotivationalStandardsBundle {
  const UsaMotivationalStandardsBundle({
    required this.versionId,
    required this.versionLabel,
    required this.source,
    required this.effectiveThrough,
    required this.events,
  });

  final String versionId;
  final String versionLabel;
  final String source;
  final int effectiveThrough;
  final List<UsaMotivationalEventStandard> events;

  factory UsaMotivationalStandardsBundle.fromJson(Map<String, dynamic> json) {
    final events = (json['events'] as List? ?? [])
        .map(
          (item) => UsaMotivationalEventStandard.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    return UsaMotivationalStandardsBundle(
      versionId: json['version_id'] as String? ?? '',
      versionLabel: json['version_label'] as String? ?? '',
      source: json['source'] as String? ?? '',
      effectiveThrough: (json['effective_through'] as num?)?.toInt() ?? 0,
      events: events,
    );
  }
}
