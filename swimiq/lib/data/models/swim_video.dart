import '../../core/utils/swim_time.dart';

class SwimVideo {
  const SwimVideo({
    this.id,
    required this.swimmerName,
    required this.storagePath,
    this.title,
    this.stroke,
    this.distance,
    this.course,
    this.videoUrl,
    this.notes,
    this.createdAt,
  });

  final int? id;
  final String swimmerName;
  final String storagePath;
  final String? title;
  final String? stroke;
  final int? distance;
  final String? course;
  final String? videoUrl;
  final String? notes;
  final DateTime? createdAt;

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    if (stroke != null && distance != null) {
      return '$distance $stroke';
    }
    return 'Swim Video';
  }

  factory SwimVideo.fromJson(Map<String, dynamic> json) {
    return SwimVideo(
      id: json['id'] as int?,
      swimmerName: json['swimmer_name'] as String? ?? '',
      storagePath: json['storage_path'] as String? ?? '',
      title: json['title'] as String?,
      stroke: json['stroke'] as String?,
      distance: (json['distance'] as num?)?.toInt(),
      course: json['course'] as String?,
      videoUrl: json['video_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'swimmer_name': swimmerName,
        'title': title,
        'stroke': stroke,
        'distance': distance,
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
    required this.swimmerName,
    required this.summary,
    required this.strengths,
    required this.improvements,
    required this.techniqueScore,
    required this.paceScore,
    required this.overallScore,
    this.analysisJson,
    this.createdAt,
  });

  final int? id;
  final int? swimVideoId;
  final String swimmerName;
  final String summary;
  final String strengths;
  final String improvements;
  final int techniqueScore;
  final int paceScore;
  final int overallScore;
  final Map<String, dynamic>? analysisJson;
  final DateTime? createdAt;

  factory SwimVideoAnalysis.fromJson(Map<String, dynamic> json) {
    return SwimVideoAnalysis(
      id: json['id'] as int?,
      swimVideoId: json['swim_video_id'] as int?,
      swimmerName: json['swimmer_name'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      strengths: json['strengths'] as String? ?? '',
      improvements: json['improvements'] as String? ?? '',
      techniqueScore: (json['technique_score'] as num?)?.toInt() ?? 0,
      paceScore: (json['pace_score'] as num?)?.toInt() ?? 0,
      overallScore: (json['overall_score'] as num?)?.toInt() ?? 0,
      analysisJson: json['analysis_json'] is Map<String, dynamic>
          ? json['analysis_json'] as Map<String, dynamic>
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'swim_video_id': swimVideoId,
        'swimmer_name': swimmerName,
        'summary': summary,
        'strengths': strengths,
        'improvements': improvements,
        'technique_score': techniqueScore,
        'pace_score': paceScore,
        'overall_score': overallScore,
        'analysis_json': analysisJson,
      };
}

class UsaTimeStandard {
  const UsaTimeStandard({
    this.id,
    required this.ageGroup,
    required this.gender,
    required this.stroke,
    required this.distance,
    required this.course,
    required this.standardLevel,
    required this.timeSeconds,
  });

  final int? id;
  final String ageGroup;
  final String gender;
  final String stroke;
  final int distance;
  final String course;
  final String standardLevel;
  final double timeSeconds;

  String get eventLabel => '$distance $stroke';

  factory UsaTimeStandard.fromJson(Map<String, dynamic> json) {
    return UsaTimeStandard(
      id: json['id'] as int?,
      ageGroup: json['age_group'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      stroke: json['stroke'] as String? ?? '',
      distance: (json['distance'] as num?)?.toInt() ?? 0,
      course: json['course'] as String? ?? '',
      standardLevel: json['standard_level'] as String? ?? '',
      timeSeconds: SwimTime.parseStoredTime(json['time_seconds']) ?? 0,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'age_group': ageGroup,
        'gender': gender,
        'stroke': stroke,
        'distance': distance,
        'course': course,
        'standard_level': standardLevel,
        'time_seconds': timeSeconds,
      };
}
