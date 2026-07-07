import '../../core/utils/swim_stroke_utils.dart';

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

  static final _structuredNotesLine = RegExp(
    r'^(Gender|Height|Weight|Dominant Hand|Training Group|Profile Photo|GPA|Athlete Website|Other Interests):\s*(.+)$',
  );

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

  String get legalName {
    final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return fullName.isNotEmpty ? fullName : swimmerName;
  }

  /// Structured metadata stored inside [athleteNotes] (no extra DB columns).
  String? get gender => _structuredNotesValue('Gender');
  String? get height => _structuredNotesValue('Height');
  String? get weight => _structuredNotesValue('Weight');
  String? get dominantHand => _structuredNotesValue('Dominant Hand');

  /// Parsed from [athleteNotes] as `Training Group: <name>`.
  String? get trainingGroup => _structuredNotesValue('Training Group');

  /// Public URL for the athlete profile photo stored in Supabase.
  String? get profilePhotoUrl => _structuredNotesValue('Profile Photo');

  /// Recruiting profile fields stored in structured notes.
  String? get gpa => _structuredNotesValue('GPA');
  String? get athleteWebsite => _structuredNotesValue('Athlete Website');
  String? get otherInterests => _structuredNotesValue('Other Interests');

  /// Free-text notes with structured prefix lines removed.
  String? get notesBody {
    final notes = athleteNotes?.trim();
    if (notes == null || notes.isEmpty) return null;
    final bodyLines = <String>[];
    for (final line in notes.split('\n')) {
      if (_structuredNotesLine.hasMatch(line.trim())) continue;
      bodyLines.add(line);
    }
    final body = bodyLines.join('\n').trim();
    return body.isEmpty ? null : body;
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
      swimmerName: _nullableText(json['swimmer_name']) ?? '',
      firstName: _nullableText(json['first_name']),
      lastName: _nullableText(json['last_name']),
      preferredName: _nullableText(json['preferred_name']),
      birthday: DateTime.tryParse(json['birthday']?.toString() ?? ''),
      graduationYear: (json['graduation_year'] as num?)?.toInt(),
      team: _nullableText(json['team']),
      coachName: _nullableText(json['coach_name']),
      primaryStroke: _normalizeStroke(json['primary_stroke'] as String?),
      secondaryStroke: _normalizeStroke(json['secondary_stroke'] as String?),
      favoriteEvent: _nullableText(json['favorite_event']),
      usaSwimmingId: _nullableText(json['usa_swimming_id']),
      school: _nullableText(json['school']),
      athleteNotes: _nullableText(json['athlete_notes']),
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

  static String composeAthleteNotes({
    String? gender,
    String? height,
    String? weight,
    String? dominantHand,
    String? trainingGroup,
    String? profilePhotoUrl,
    String? gpa,
    String? athleteWebsite,
    String? otherInterests,
    String? notes,
  }) {
    final parts = <String>[];
    void addLine(String label, String? value) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) {
        parts.add('$label: $text');
      }
    }

    addLine('Gender', gender);
    addLine('Height', height);
    addLine('Weight', weight);
    addLine('Dominant Hand', dominantHand);
    addLine('Training Group', trainingGroup);
    addLine('Profile Photo', profilePhotoUrl);
    addLine('GPA', gpa);
    addLine('Athlete Website', athleteWebsite);
    addLine('Other Interests', otherInterests);

    final body = notes?.trim();
    if (body != null && body.isNotEmpty) {
      parts.add(body);
    }
    return parts.join('\n');
  }

  static ({String? firstName, String? lastName}) splitLegalName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return (firstName: null, lastName: null);
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return (firstName: parts.first, lastName: null);
    }
    return (firstName: parts.first, lastName: parts.sublist(1).join(' '));
  }

  String? _structuredNotesValue(String label) {
    final notes = athleteNotes?.trim();
    if (notes == null || notes.isEmpty) return null;
    final pattern = RegExp('^$label:\\s*(.+)\$');
    for (final line in notes.split('\n')) {
      final match = pattern.firstMatch(line.trim());
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _nullableText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _normalizeStroke(String? value) {
    final canonical = SwimStrokeUtils.canonical(value);
    return canonical.isEmpty ? null : canonical;
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
