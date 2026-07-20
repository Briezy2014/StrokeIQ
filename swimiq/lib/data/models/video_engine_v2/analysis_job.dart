/// Async analysis job status from Video Engine V2.
class AnalysisJob {
  const AnalysisJob({
    required this.jobId,
    required this.status,
    required this.stage,
    required this.engineVersion,
    this.videoId,
    this.progress,
    this.errorCode,
    this.errorMessage,
    this.retriable = false,
    this.retryCount = 0,
    this.createdAt,
    this.updatedAt,
    this.limitations = const [],
    this.hasReport = false,
    this.hasMetrics = false,
  });

  final String jobId;
  final String status;
  final String stage;
  final String engineVersion;
  final String? videoId;

  /// Backend progress fraction (0–1). UI must show [stageLabel], not a fake %.
  final double? progress;

  final String? errorCode;
  final String? errorMessage;
  final bool retriable;
  final int retryCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> limitations;
  final bool hasReport;
  final bool hasMetrics;

  bool get isTerminal =>
      status == 'completed' ||
      status == 'completed_with_limitations' ||
      status == 'failed' ||
      status == 'cancelled';

  bool get isSuccess =>
      status == 'completed' || status == 'completed_with_limitations';

  bool get isFailed => status == 'failed';

  bool get isCancelled => status == 'cancelled';

  bool get canCancel => !isTerminal;

  bool get canRetry => isFailed && retriable;

  /// Human-readable stage for progress UI (never invent a percentage).
  String get stageLabel => stageDisplayLabel(stage);

  /// Athlete/parent/coach-facing status — never expose "limitations".
  String get statusLabel {
    switch (status.trim().toLowerCase()) {
      case 'completed':
      case 'completed_with_limitations':
        return 'Complete';
      case 'failed':
        return 'Could not finish';
      case 'cancelled':
        return 'Cancelled';
      case 'queued':
        return 'Queued';
      case 'processing':
      case 'running':
        return 'Working';
      default:
        final cleaned = status.replaceAll('_', ' ').trim();
        if (cleaned.isEmpty) return 'Working';
        if (cleaned.toLowerCase().contains('limitation')) return 'Complete';
        return cleaned[0].toUpperCase() + cleaned.substring(1);
    }
  }

  static String stageDisplayLabel(String stage) {
    switch (stage.trim().toLowerCase()) {
      case 'queued':
        return 'Queued';
      case 'downloading':
        return 'Downloading video';
      case 'validating':
        return 'Validating video';
      case 'preprocessing':
        return 'Preprocessing';
      case 'detecting_swimmer':
        return 'Detecting swimmer';
      case 'estimating_pose':
        return 'Estimating pose';
      case 'detecting_events':
        return 'Detecting events';
      case 'calculating_metrics':
        return 'Calculating metrics';
      case 'validating_results':
        return 'Validating results';
      case 'generating_report':
        return 'Generating report';
      case 'completed':
        return 'Completed';
      case 'completed_with_limitations':
        // Keep athlete/parent/coach-facing copy professional — no "limitations".
        return 'Report ready';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        final cleaned = stage.replaceAll('_', ' ').trim();
        if (cleaned.isEmpty) return 'Processing';
        return cleaned[0].toUpperCase() + cleaned.substring(1);
    }
  }

  factory AnalysisJob.fromJson(Map<String, dynamic> json) {
    final error = json['error'];
    String? errorCode;
    String? errorMessage;
    var retriable = false;
    if (error is Map) {
      errorCode = error['error_code']?.toString();
      errorMessage = error['message']?.toString();
      retriable = error['retriable'] == true;
    } else {
      errorCode = json['error_code']?.toString();
      errorMessage = json['error_message']?.toString() ??
          json['message']?.toString();
    }

    final progressRaw = json['progress'];
    double? progress;
    if (progressRaw is num) {
      progress = progressRaw.toDouble();
    }

    return AnalysisJob(
      jobId: (json['job_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? 'queued').toString(),
      stage: (json['stage'] ?? json['status'] ?? 'queued').toString(),
      engineVersion: (json['engine_version'] ?? '').toString(),
      videoId: json['video_id']?.toString(),
      progress: progress,
      errorCode: errorCode,
      errorMessage: errorMessage,
      retriable: retriable,
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      limitations: _stringList(json['limitations']),
      hasReport: json['has_report'] == true,
      hasMetrics: json['has_metrics'] == true,
    );
  }

  AnalysisJob copyWith({
    String? status,
    String? stage,
    double? progress,
    String? errorCode,
    String? errorMessage,
    bool? retriable,
    int? retryCount,
    List<String>? limitations,
  }) {
    return AnalysisJob(
      jobId: jobId,
      status: status ?? this.status,
      stage: stage ?? this.stage,
      engineVersion: engineVersion,
      videoId: videoId,
      progress: progress ?? this.progress,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      retriable: retriable ?? this.retriable,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      limitations: limitations ?? this.limitations,
      hasReport: hasReport,
      hasMetrics: hasMetrics,
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList(growable: false);
  }
}
