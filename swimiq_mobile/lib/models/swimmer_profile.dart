/// Athlete Passport profile from the `swimmers` Supabase table.
class SwimmerProfile {
  const SwimmerProfile({
    this.id,
    required this.swimmerName,
    this.firstName,
    this.lastName,
    this.preferredName,
    this.team,
    this.coachName,
    this.primaryStroke,
    this.secondaryStroke,
    this.favoriteEvent,
    this.graduationYear,
    this.school,
    this.usaSwimmingId,
    this.athleteNotes,
    this.birthday,
  });

  final String? id;
  final String swimmerName;
  final String? firstName;
  final String? lastName;
  final String? preferredName;
  final String? team;
  final String? coachName;
  final String? primaryStroke;
  final String? secondaryStroke;
  final String? favoriteEvent;
  final int? graduationYear;
  final String? school;
  final String? usaSwimmingId;
  final String? athleteNotes;
  final DateTime? birthday;

  String get displayName {
    if (preferredName != null && preferredName!.trim().isNotEmpty) {
      return preferredName!.trim();
    }

    final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return swimmerName;
  }

  factory SwimmerProfile.fromJson(Map<String, dynamic> json) {
    return SwimmerProfile(
      id: json['id']?.toString(),
      swimmerName: json['swimmer_name'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      preferredName: json['preferred_name'] as String?,
      team: json['team'] as String?,
      coachName: json['coach_name'] as String?,
      primaryStroke: json['primary_stroke'] as String?,
      secondaryStroke: json['secondary_stroke'] as String?,
      favoriteEvent: json['favorite_event'] as String?,
      graduationYear: json['graduation_year'] as int?,
      school: json['school'] as String?,
      usaSwimmingId: json['usa_swimming_id'] as String?,
      athleteNotes: json['athlete_notes'] as String?,
      birthday: _parseBirthday(json['birthday']),
    );
  }

  static DateTime? _parseBirthday(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'swimmer_name': swimmerName,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (preferredName != null) 'preferred_name': preferredName,
      if (team != null) 'team': team,
      if (coachName != null) 'coach_name': coachName,
      if (primaryStroke != null) 'primary_stroke': primaryStroke,
      if (secondaryStroke != null) 'secondary_stroke': secondaryStroke,
      if (favoriteEvent != null) 'favorite_event': favoriteEvent,
      if (graduationYear != null) 'graduation_year': graduationYear,
      if (school != null) 'school': school,
      if (usaSwimmingId != null) 'usa_swimming_id': usaSwimmingId,
      if (athleteNotes != null) 'athlete_notes': athleteNotes,
      if (birthday != null) 'birthday': birthday!.toIso8601String().split('T').first,
    };
  }
}
