/// Pool course for USA Swimming standards.
enum SwimCourse {
  scy('SCY'),
  scm('SCM'),
  lcm('LCM');

  const SwimCourse(this.code);

  final String code;

  static SwimCourse? fromCode(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim().toUpperCase();
    for (final course in SwimCourse.values) {
      if (course.code == normalized) {
        return course;
      }
    }
    return null;
  }
}
