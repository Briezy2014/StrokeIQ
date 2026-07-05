import 'standard_level.dart';
import 'swim_course.dart';
import 'swim_gender.dart';

/// One row from the `motivational_standards` Supabase table.
class MotivationalStandard {
  const MotivationalStandard({
    this.id,
    required this.ageGroup,
    required this.gender,
    required this.course,
    required this.event,
    required this.bTime,
    required this.bbTime,
    required this.aTime,
    required this.aaTime,
    required this.aaaTime,
    required this.aaaaTime,
    required this.version,
  });

  final String? id;
  final String ageGroup;
  final String gender;
  final String course;
  final String event;
  final double bTime;
  final double bbTime;
  final double aTime;
  final double aaTime;
  final double aaaTime;
  final double aaaaTime;
  final String version;

  SwimCourse? get courseEnum => SwimCourse.fromCode(course);

  SwimGender? get genderEnum => SwimGender.fromCode(gender);

  double timeForLevel(StandardLevel level) {
    switch (level) {
      case StandardLevel.b:
        return bTime;
      case StandardLevel.bb:
        return bbTime;
      case StandardLevel.a:
        return aTime;
      case StandardLevel.aa:
        return aaTime;
      case StandardLevel.aaa:
        return aaaTime;
      case StandardLevel.aaaa:
        return aaaaTime;
    }
  }

  factory MotivationalStandard.fromJson(Map<String, dynamic> json) {
    double readTime(String key) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      return double.parse(value.toString());
    }

    return MotivationalStandard(
      id: json['id']?.toString(),
      ageGroup: json['age_group'] as String,
      gender: json['gender'] as String,
      course: json['course'] as String,
      event: json['event'] as String,
      bTime: readTime('b_time'),
      bbTime: readTime('bb_time'),
      aTime: readTime('a_time'),
      aaTime: readTime('aa_time'),
      aaaTime: readTime('aaa_time'),
      aaaaTime: readTime('aaaa_time'),
      version: json['version'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'age_group': ageGroup,
      'gender': gender,
      'course': course,
      'event': event,
      'b_time': bTime,
      'bb_time': bbTime,
      'a_time': aTime,
      'aa_time': aaTime,
      'aaa_time': aaaTime,
      'aaaa_time': aaaaTime,
      'version': version,
    };
  }
}
