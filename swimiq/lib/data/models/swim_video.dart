import '../../core/utils/supabase_parsers.dart';

class SwimVideo {
  const SwimVideo({
    this.id,
    required this.swimmer,
    required this.storagePath,
    this.title,
    this.stroke,
    this.distance,
    this.course,
    this.videoUrl,
    this.notes,
    this.createdAt,
  });

  final String? id;
  final String swimmer;
  final String storagePath;
  final String? title;
  final String? stroke;
  final String? distance;
  final String? course;
  final String? videoUrl;
  final String? notes;
  final DateTime? createdAt;

  String get swimmerName => swimmer;

  int? get distanceMeters => parseOptionalInt(distance);

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    if (stroke != null && distance != null) {
      return '$distance $stroke';
    }
    return 'Swim Video';
  }

  factory SwimVideo.fromJson(Map<String, dynamic> json) {
    return SwimVideo(
      id: parseUuid(json['id']),
      swimmer: swimmerFromJson(json),
      storagePath: parseOptionalText(json['storage_path']) ?? '',
      title: parseOptionalText(json['title']),
      stroke: parseOptionalText(json['stroke']),
      distance: parseOptionalText(json['distance']),
      course: parseOptionalText(json['course']),
      videoUrl: parseOptionalText(json['video_url']),
      notes: parseOptionalText(json['notes']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  factory SwimVideo.fromSupabaseRow(dynamic row) {
    return SwimVideo.fromJson(supabaseRowToMap(row));
  }

  SwimVideo copyWith({
    String? id,
    String? swimmer,
    String? storagePath,
    String? title,
    String? stroke,
    String? distance,
    String? course,
    String? videoUrl,
    String? notes,
    DateTime? createdAt,
  }) {
    return SwimVideo(
      id: id ?? this.id,
      swimmer: swimmer ?? this.swimmer,
      storagePath: storagePath ?? this.storagePath,
      title: title ?? this.title,
      stroke: stroke ?? this.stroke,
      distance: distance ?? this.distance,
      course: course ?? this.course,
      videoUrl: videoUrl ?? this.videoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'swimmer': swimmer,
        'title': title,
        'stroke': stroke,
        'distance': distance?.toString(),
        'course': course,
        'storage_path': storagePath,
        'video_url': videoUrl,
        'notes': notes,
      };
}

class SwimVideoAnalysis {
  const SwimVideoAnalysis({
    this.id,
    this.swimVideoId,
    required this.swimmer,
    required this.summary,
    required this.strengths,
    required this.improvements,
    required this.techniqueScore,
    required this.paceScore,
    required this.overallScore,
    this.analysisJson,
    this.createdAt,
  });

  final String? id;
  final String? swimVideoId;
  final String swimmer;
  final String summary;
  final String strengths;
  final String improvements;
  final int techniqueScore;
  final int paceScore;
  final int overallScore;
  final Map<String, dynamic>? analysisJson;
  final DateTime? createdAt;

  String get swimmerName => swimmer;

  factory SwimVideoAnalysis.fromJson(Map<String, dynamic> json) {
    return SwimVideoAnalysis(
      id: parseUuid(json['id']),
      swimVideoId: parseUuid(json['swim_video_id']),
      swimmer: swimmerFromJson(json),
      summary: parseOptionalText(json['summary']) ?? '',
      strengths: parseOptionalText(json['strengths']) ?? '',
      improvements: parseOptionalText(json['improvements']) ?? '',
      techniqueScore: parseOptionalInt(json['technique_score']) ?? 0,
      paceScore: parseOptionalInt(json['pace_score']) ?? 0,
      overallScore: parseOptionalInt(json['overall_score']) ?? 0,
      analysisJson: json['analysis_json'] is Map
          ? Map<String, dynamic>.from(json['analysis_json'] as Map)
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  factory SwimVideoAnalysis.fromSupabaseRow(dynamic row) {
    return SwimVideoAnalysis.fromJson(supabaseRowToMap(row));
  }

  Map<String, dynamic> toInsertJson() => {
        'swim_video_id': swimVideoId,
        'swimmer': swimmer,
        'summary': summary,
        'strengths': strengths,
        'improvements': improvements,
        'technique_score': techniqueScore,
        'pace_score': paceScore,
        'overall_score': overallScore,
        'analysis_json': analysisJson,
      };
}
