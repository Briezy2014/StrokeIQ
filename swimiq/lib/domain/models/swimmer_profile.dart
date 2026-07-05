class SwimmerProfile {
  const SwimmerProfile({
    this.id,
    required this.swimmerName,
    this.firstName,
    this.lastName,
    this.preferredName,
    this.birthday,
    this.graduationYear,
    this.team,
    this.coachName,
    this.primaryStroke,
    this.secondaryStroke,
    this.favoriteEvent,
    this.usaSwimmingId,
    this.school,
    this.athleteNotes,
  });

  final String? id;
  final String swimmerName;
  final String? firstName;
  final String? lastName;
  final String? preferredName;
  final DateTime? birthday;
  final int? graduationYear;
  final String? team;
  final String? coachName;
  final String? primaryStroke;
  final String? secondaryStroke;
  final String? favoriteEvent;
  final String? usaSwimmingId;
  final String? school;
  final String? athleteNotes;

  String get displayName {
    if (preferredName != null && preferredName!.isNotEmpty) {
      return preferredName!;
    }
    final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (fullName.isNotEmpty) return fullName;
    return swimmerName;
  }

  factory SwimmerProfile.fromJson(Map<String, dynamic> json) {
    return SwimmerProfile(
      id: json['id']?.toString(),
      swimmerName: json['swimmer_name']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      preferredName: json['preferred_name']?.toString(),
      birthday: _parseDate(json['birthday']),
      graduationYear: _parseInt(json['graduation_year']),
      team: json['team']?.toString(),
      coachName: json['coach_name']?.toString(),
      primaryStroke: json['primary_stroke']?.toString(),
      secondaryStroke: json['secondary_stroke']?.toString(),
      favoriteEvent: json['favorite_event']?.toString(),
      usaSwimmingId: json['usa_swimming_id']?.toString(),
      school: json['school']?.toString(),
      athleteNotes: json['athlete_notes']?.toString(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'swimmer_name': swimmerName,
      'first_name': firstName,
      'last_name': lastName,
      'preferred_name': preferredName,
      'birthday': birthday != null ? _formatDate(birthday!) : null,
      'graduation_year': graduationYear,
      'team': team,
      'coach_name': coachName,
      'primary_stroke': primaryStroke,
      'secondary_stroke': secondaryStroke,
      'favorite_event': favoriteEvent,
      'usa_swimming_id': usaSwimmingId,
      'school': school,
      'athlete_notes': athleteNotes,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
