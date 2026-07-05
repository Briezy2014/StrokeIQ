/// Resolves USA Swimming motivational age groups from swimmer age.
abstract final class AgeGroupResolver {
  static const groups = [
    '10 & Under',
    '11-12',
    '13-14',
    '15-16',
    '17-18',
  ];

  /// Returns the motivational age group for [age] (USA Swimming banded groups).
  static String? fromAge(int age) {
    if (age <= 10) {
      return '10 & Under';
    }
    if (age <= 12) {
      return '11-12';
    }
    if (age <= 14) {
      return '13-14';
    }
    if (age <= 16) {
      return '15-16';
    }
    if (age <= 18) {
      return '17-18';
    }
    return null;
  }

  /// Age on December 31 of [referenceYear] (common USA Swimming convention).
  static int ageOnDecember31(DateTime birthday, {int? referenceYear}) {
    return (referenceYear ?? DateTime.now().year) - birthday.year;
  }

  static String? fromBirthday(DateTime birthday, {int? referenceYear}) {
    return fromAge(ageOnDecember31(birthday, referenceYear: referenceYear));
  }
}
