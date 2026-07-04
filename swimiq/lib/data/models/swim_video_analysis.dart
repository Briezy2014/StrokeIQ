import '../../core/utils/supabase_parsers.dart';

/// Canonical AI analysis model for Video Lab.
///
/// Do not duplicate this class elsewhere. Import [video_models.dart] in consumers.
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

  SwimVideoAnalysis copyWith({
    String? id,
    String? swimVideoId,
    String? swimmer,
    String? summary,
    String? strengths,
    String? improvements,
    int? techniqueScore,
    int? paceScore,
    int? overallScore,
    Map<String, dynamic>? analysisJson,
    DateTime? createdAt,
  }) {
    return SwimVideoAnalysis(
      id: id ?? this.id,
      swimVideoId: swimVideoId ?? this.swimVideoId,
      swimmer: swimmer ?? this.swimmer,
      summary: summary ?? this.summary,
      strengths: strengths ?? this.strengths,
      improvements: improvements ?? this.improvements,
      techniqueScore: techniqueScore ?? this.techniqueScore,
      paceScore: paceScore ?? this.paceScore,
      overallScore: overallScore ?? this.overallScore,
      analysisJson: analysisJson ?? this.analysisJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'swim_video_id': swimVideoId,
        'swimmer': swimmer,
        'swimmer_name': swimmer,
        'summary': summary,
        'strengths': strengths,
        'improvements': improvements,
        'technique_score': techniqueScore,
        'pace_score': paceScore,
        'overall_score': overallScore,
        'analysis_json': analysisJson,
      };
}
