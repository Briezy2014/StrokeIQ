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

  final int? id;
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
    if (preferredName != null && preferredName!.trim().isNotEmpty) {
      return preferredName!.trim();
    }
    final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return fullName.isNotEmpty ? fullName : swimmerName;
  }

  int? get age {
    if (birthday == null) return null;
    final today = DateTime.now();
    var years = today.year - birthday!.year;
    if (today.month < birthday!.month ||
        (today.month == birthday!.month && today.day < birthday!.day)) {
      years--;
    }
    return years;
  }

  factory SwimmerProfile.fromJson(Map<String, dynamic> json) {
    return SwimmerProfile(
      id: json['id'] as int?,
      swimmerName: json['swimmer_name'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      preferredName: json['preferred_name'] as String?,
      birthday: DateTime.tryParse(json['birthday']?.toString() ?? ''),
      graduationYear: (json['graduation_year'] as num?)?.toInt(),
      team: json['team'] as String?,
      coachName: json['coach_name'] as String?,
      primaryStroke: json['primary_stroke'] as String?,
      secondaryStroke: json['secondary_stroke'] as String?,
      favoriteEvent: json['favorite_event'] as String?,
      usaSwimmingId: json['usa_swimming_id'] as String?,
      school: json['school'] as String?,
      athleteNotes: json['athlete_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'swimmer_name': swimmerName,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'preferred_name': preferredName ?? '',
        'birthday': birthday != null ? _formatDate(birthday!) : null,
        'graduation_year': graduationYear,
        'team': team ?? '',
        'coach_name': coachName ?? '',
        'primary_stroke': primaryStroke ?? '',
        'secondary_stroke': secondaryStroke ?? '',
        'favorite_event': favoriteEvent ?? '',
        'usa_swimming_id': usaSwimmingId ?? '',
        'school': school ?? '',
        'athlete_notes': athleteNotes ?? '',
      };

  SwimmerProfile copyWith({
    int? id,
    String? swimmerName,
    String? firstName,
    String? lastName,
    String? preferredName,
    DateTime? birthday,
    int? graduationYear,
    String? team,
    String? coachName,
    String? primaryStroke,
    String? secondaryStroke,
    String? favoriteEvent,
    String? usaSwimmingId,
    String? school,
    String? athleteNotes,
  }) {
    return SwimmerProfile(
      id: id ?? this.id,
      swimmerName: swimmerName ?? this.swimmerName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      preferredName: preferredName ?? this.preferredName,
      birthday: birthday ?? this.birthday,
      graduationYear: graduationYear ?? this.graduationYear,
      coachName: coachName ?? this.coachName,
      team: team ?? this.team,
      primaryStroke: primaryStroke ?? this.primaryStroke,
      secondaryStroke: secondaryStroke ?? this.secondaryStroke,
      favoriteEvent: favoriteEvent ?? this.favoriteEvent,
      usaSwimmingId: usaSwimmingId ?? this.usaSwimmingId,
      school: school ?? this.school,
      athleteNotes: athleteNotes ?? this.athleteNotes,
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
