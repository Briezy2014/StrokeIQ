import '../../core/utils/supabase_parsers.dart';
import 'swim_pose_metrics.dart';

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

  Map<String, String> get coachingSections {
    final raw = analysisJson?['sections'];
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  List<String> get topPriorities {
    final top3 = analysisJson?['top_3_priorities'];
    if (top3 is List) {
      return top3.map((item) => item.toString()).toList();
    }
    final legacy = analysisJson?['top_5_priorities'];
    if (legacy is List) {
      return legacy.map((item) => item.toString()).toList();
    }
    return const [];
  }

  String? get disclaimer => analysisJson?['disclaimer']?.toString();

  String? get analysisEngine => analysisJson?['engine']?.toString();

  /// Old rule-based engine stored in Supabase before notes-driven V1.
  bool get isLegacyRulesEngine {
    final engine = analysisEngine;
    if (engine == 'swimiq-v1-rules') return true;
    // Gemini / modern engines are never "legacy rules", even without sections.
    if (isGeminiEngine) return false;
    if (engine != null && engine.startsWith('swimiq-v2')) return false;
    final summaryLower = summary.toLowerCase();
    if (summaryLower.contains('overall readiness score')) return true;
    if (summaryLower.contains('consistent training history')) return true;
    if (engine == 'swimiq-v1-notes' &&
        coachingSections.isNotEmpty &&
        !coachingSections.containsKey('Quick Summary')) {
      return true;
    }
    if (engine != 'swimiq-v1-notes' && coachingSections.isEmpty) {
      return true;
    }
    return false;
  }

  bool get isNotesDriven => analysisEngine == 'swimiq-v1-notes';

  bool get isGeminiEngine => analysisEngine == 'swimiq-v2-gemini' ||
      analysisEngine == 'swimiq-v2-gemini-mediapipe';

  bool get hasPoseMetrics => analysisJson?['pose_metrics'] is Map;

  SwimPoseMetrics? get poseMetrics {
    final raw = analysisJson?['pose_metrics'];
    if (raw is! Map) return null;
    return SwimPoseMetrics.fromJson(Map<String, dynamic>.from(raw));
  }

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
