import 'analysis_job.dart';
import 'analysis_metric.dart';

/// Structured results payload from `GET /v1/analyses/{job_id}/results`.
class AnalysisResults {
  const AnalysisResults({
    required this.jobId,
    required this.status,
    required this.engineVersion,
    this.videoId,
    this.metrics = const [],
    this.phases = const [],
    this.limitations = const [],
    this.report,
    this.evidence = const [],
    this.errorCode,
    this.errorMessage,
    this.stroke,
    this.athlete,
    this.video,
    this.modelVersions = const {},
    this.tracking,
    this.createdAt,
  });

  final String jobId;
  final String status;
  final String engineVersion;
  final String? videoId;
  final List<AnalysisMetric> metrics;
  final List<AnalysisPhase> phases;
  final List<String> limitations;
  final AnalysisReport? report;
  final List<AnalysisEvidence> evidence;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? stroke;
  final Map<String, dynamic>? athlete;
  final Map<String, dynamic>? video;
  final Map<String, String> modelVersions;
  final Map<String, dynamic>? tracking;
  final DateTime? createdAt;

  bool get isFailed => status == 'failed';
  bool get isPartialSuccess => status == 'completed_with_limitations';
  bool get isCompleted => status == 'completed' || isPartialSuccess;
  bool get hasDeterministicMetrics => metrics.isNotEmpty;
  bool get hasReport => report != null && report!.isAvailable;
  bool get reportFailed =>
      isCompleted && (!hasReport || report?.geminiSucceeded == false);

  /// Failures caused by the clip itself (retrying the same file usually fails again).
  bool get isClipQualityFailure {
    switch ((errorCode ?? '').toUpperCase()) {
      case 'TARGET_LOST_EXTENDED':
      case 'TARGET_SWIMMER_NOT_FOUND':
      case 'NO_DETECTIONS':
      case 'INSUFFICIENT_POSE':
      case 'POSE_FAILED':
      case 'INSUFFICIENT_POSE_EVIDENCE':
      case 'INVALID_VIDEO':
      case 'UNSUPPORTED_CODEC':
      case 'VIDEO_TOO_LARGE':
        return true;
      default:
        return false;
    }
  }

  String get stageLabel => AnalysisJob.stageDisplayLabel(status);

  factory AnalysisResults.fromJson(Map<String, dynamic> json) {
    final error = json['error'];
    String? errorCode;
    String? errorMessage;
    if (error is Map) {
      errorCode = error['error_code']?.toString();
      errorMessage = error['message']?.toString();
    }

    final metricsRaw = json['metrics'];
    final metrics = <AnalysisMetric>[];
    if (metricsRaw is List) {
      for (final item in metricsRaw) {
        if (item is Map) {
          metrics.add(
            AnalysisMetric.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final phasesRaw = json['phases'];
    final phases = <AnalysisPhase>[];
    if (phasesRaw is List) {
      for (final item in phasesRaw) {
        if (item is Map) {
          phases.add(AnalysisPhase.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final evidenceRaw = json['evidence_frames'] ?? json['evidence'];
    final evidence = <AnalysisEvidence>[];
    if (evidenceRaw is List) {
      for (final item in evidenceRaw) {
        if (item is Map) {
          evidence.add(
            AnalysisEvidence.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    AnalysisReport? report;
    final reportRaw = json['report'];
    if (reportRaw is Map) {
      report = AnalysisReport.fromJson(Map<String, dynamic>.from(reportRaw));
    }

    final modelVersions = <String, String>{};
    final mv = json['model_versions'];
    if (mv is Map) {
      mv.forEach((k, v) {
        if (v != null) modelVersions[k.toString()] = v.toString();
      });
    }

    return AnalysisResults(
      jobId: (json['job_id'] ?? '').toString(),
      status: (json['status'] ?? 'completed').toString(),
      engineVersion: (json['engine_version'] ?? '').toString(),
      videoId: json['video_id']?.toString(),
      metrics: metrics,
      phases: phases,
      limitations: _stringList(json['limitations']),
      report: report,
      evidence: evidence,
      errorCode: errorCode,
      errorMessage: errorMessage,
      stroke: _mapOrNull(json['stroke']),
      athlete: _mapOrNull(json['athlete']),
      video: _mapOrNull(json['video']),
      modelVersions: modelVersions,
      tracking: _mapOrNull(json['tracking']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList(growable: false);
  }

  static Map<String, dynamic>? _mapOrNull(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }
}

class AnalysisPhase {
  const AnalysisPhase({
    required this.name,
    this.startMs,
    this.endMs,
    this.startFrame,
    this.endFrame,
    this.confidence,
    this.qualityFlags = const [],
    this.evidenceFrames = const [],
  });

  final String name;
  final int? startMs;
  final int? endMs;
  final int? startFrame;
  final int? endFrame;
  final double? confidence;
  final List<String> qualityFlags;
  final List<int> evidenceFrames;

  String get displayName =>
      name.replaceAll('_', ' ').trim().replaceFirstMapped(
            RegExp(r'^[a-z]'),
            (m) => m.group(0)!.toUpperCase(),
          );

  factory AnalysisPhase.fromJson(Map<String, dynamic> json) {
    return AnalysisPhase(
      name: (json['name'] ?? 'phase').toString(),
      startMs: (json['start_ms'] as num?)?.toInt(),
      endMs: (json['end_ms'] as num?)?.toInt(),
      startFrame: (json['start_frame'] as num?)?.toInt(),
      endFrame: (json['end_frame'] as num?)?.toInt(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      qualityFlags: _stringList(json['quality_flags']),
      evidenceFrames: _intList(json['evidence_frames']),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList(growable: false);
  }

  static List<int> _intList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e is num ? e.toInt() : int.tryParse(e.toString()))
        .whereType<int>()
        .toList(growable: false);
  }
}

class AnalysisReport {
  const AnalysisReport({
    this.summary,
    this.strengths = const [],
    this.priorityImprovements = const [],
    this.raceRecommendations = const [],
    this.limitationsStatement,
    this.model,
    this.createdAt,
    this.geminiSucceeded,
    this.drills = const [],
  });

  final String? summary;
  final List<String> strengths;
  final List<PriorityImprovement> priorityImprovements;
  final List<String> raceRecommendations;
  final String? limitationsStatement;
  final String? model;
  final DateTime? createdAt;
  final bool? geminiSucceeded;
  final List<String> drills;

  bool get isAvailable =>
      (summary != null && summary!.trim().isNotEmpty) ||
      strengths.isNotEmpty ||
      priorityImprovements.isNotEmpty;

  factory AnalysisReport.fromJson(Map<String, dynamic> json) {
    final improvements = <PriorityImprovement>[];
    final raw = json['priority_improvements'] ?? json['priorityImprovements'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          improvements.add(
            PriorityImprovement.fromJson(Map<String, dynamic>.from(item)),
          );
        } else if (item != null) {
          improvements.add(
            PriorityImprovement(title: item.toString()),
          );
        }
      }
    }

    final drills = <String>[];
    for (final improvement in improvements) {
      drills.addAll(improvement.drills);
    }
    final drillsRaw = json['drills'];
    if (drillsRaw is List) {
      drills.addAll(drillsRaw.map((e) => e.toString()));
    }

    return AnalysisReport(
      summary: json['summary']?.toString(),
      strengths: _stringList(json['strengths']),
      priorityImprovements: improvements,
      raceRecommendations: _stringList(json['race_recommendations']),
      limitationsStatement: json['limitations_statement']?.toString(),
      model: json['model']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      geminiSucceeded: json['gemini_succeeded'] as bool?,
      drills: drills.toSet().toList(growable: false),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList(growable: false);
  }
}

class PriorityImprovement {
  const PriorityImprovement({
    required this.title,
    this.evidenceMetricNames = const [],
    this.drills = const [],
  });

  final String title;
  final List<String> evidenceMetricNames;
  final List<String> drills;

  factory PriorityImprovement.fromJson(Map<String, dynamic> json) {
    return PriorityImprovement(
      title: (json['title'] ?? json['name'] ?? 'Improvement').toString(),
      evidenceMetricNames: _stringList(
        json['evidence_metric_names'] ?? json['evidenceMetricNames'],
      ),
      drills: _stringList(json['drills']),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList(growable: false);
  }
}

class AnalysisEvidence {
  const AnalysisEvidence({
    this.path,
    this.label,
    this.frameNumber,
    this.raw = const {},
  });

  final String? path;
  final String? label;
  final int? frameNumber;
  final Map<String, dynamic> raw;

  String get displayLabel {
    if (label != null && label!.trim().isNotEmpty) return label!.trim();
    if (frameNumber != null) return 'Frame $frameNumber';
    if (path != null && path!.trim().isNotEmpty) {
      final parts = path!.split('/');
      return parts.isNotEmpty ? parts.last : path!;
    }
    if (raw.isNotEmpty) return raw.keys.first;
    return 'Evidence';
  }

  factory AnalysisEvidence.fromJson(Map<String, dynamic> json) {
    return AnalysisEvidence(
      path: json['path']?.toString(),
      label: json['label']?.toString(),
      frameNumber: (json['frame_number'] as num?)?.toInt(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}
