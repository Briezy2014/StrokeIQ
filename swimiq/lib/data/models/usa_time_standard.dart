import '../../core/utils/swim_time.dart';
import '../../core/utils/supabase_parsers.dart';

class UsaTimeStandard {
  const UsaTimeStandard({
    this.id,
    required this.ageGroup,
    required this.gender,
    required this.stroke,
    required this.distance,
    required this.course,
    required this.standardLevel,
    required this.timeSeconds,
  });

  final String? id;
  final String ageGroup;
  final String gender;
  final String stroke;
  final int distance;
  final String course;
  final String standardLevel;
  final double timeSeconds;

  String get eventLabel => '$distance $stroke';

  factory UsaTimeStandard.fromJson(Map<String, dynamic> json) {
    return UsaTimeStandard(
      id: parseUuid(json['id']),
      ageGroup: json['age_group'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      stroke: json['stroke'] as String? ?? '',
      distance: parseOptionalInt(json['distance']) ?? 0,
      course: json['course'] as String? ?? '',
      standardLevel: json['standard_level'] as String? ?? '',
      timeSeconds: SwimTime.parseStoredTime(json['time_seconds']) ?? 0,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'age_group': ageGroup,
        'gender': gender,
        'stroke': stroke,
        'distance': distance,
        'course': course,
        'standard_level': standardLevel,
        'time_seconds': timeSeconds,
      };
}
