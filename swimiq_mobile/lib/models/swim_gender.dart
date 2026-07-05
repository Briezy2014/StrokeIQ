/// Gender for USA Swimming motivational standards lookups.
enum SwimGender {
  female('F', 'Female'),
  male('M', 'Male');

  const SwimGender(this.code, this.label);

  final String code;
  final String label;

  static SwimGender? fromCode(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim().toUpperCase();
    if (normalized == 'F' || normalized == 'FEMALE' || normalized == 'GIRLS' || normalized == 'GIRL') {
      return SwimGender.female;
    }
    if (normalized == 'M' || normalized == 'MALE' || normalized == 'BOYS' || normalized == 'BOY') {
      return SwimGender.male;
    }
    return null;
  }
}
