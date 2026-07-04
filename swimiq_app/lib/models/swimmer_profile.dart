class SwimmerProfile {
  SwimmerProfile({
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
  final String? birthday;
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

  String get initials {
    final name = displayName;
    if (name.isEmpty) return '🏊';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  factory SwimmerProfile.fromJson(Map<String, dynamic> json) {
    return SwimmerProfile(
      id: json['id'] as int?,
      swimmerName: json['swimmer_name']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      preferredName: json['preferred_name']?.toString(),
      birthday: json['birthday']?.toString(),
      graduationYear: (json['graduation_year'] as num?)?.toInt(),
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

  Map<String, dynamic> toJson() {
    return {
      'swimmer_name': swimmerName,
      'first_name': firstName,
      'last_name': lastName,
      'preferred_name': preferredName,
      'birthday': birthday,
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
}
