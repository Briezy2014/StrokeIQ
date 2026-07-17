import 'package:flutter/foundation.dart';

/// Lightweight analytics for Video Engine V2 flows.
///
/// Never log raw video bytes or file path contents.
class VideoAnalyticsService {
  const VideoAnalyticsService();

  static const uploadStarted = 'video_upload_started';
  static const uploadSucceeded = 'video_upload_succeeded';
  static const uploadFailed = 'video_upload_failed';
  static const analysisJobCreated = 'analysis_job_created';
  static const analysisStageChanged = 'analysis_stage_changed';
  static const analysisCompleted = 'analysis_completed';
  static const analysisFailed = 'analysis_failed';
  static const analysisCancelled = 'analysis_cancelled';
  static const analysisRetry = 'analysis_retry';
  static const reportUnavailable = 'report_unavailable';
  static const historyOpened = 'history_opened';

  void logEvent(String name, [Map<String, Object?> props = const {}]) {
    final sanitized = <String, Object?>{};
    props.forEach((key, value) {
      final k = key.toLowerCase();
      if (k.contains('bytes') ||
          k.contains('file_content') ||
          k.contains('raw_video') ||
          k == 'content' ||
          k == 'body') {
        return;
      }
      // Keep path keys only as basename-safe metadata strings, never binary.
      if (value is List<int> || value is List<num>) {
        sanitized[key] = '<omitted binary>';
        return;
      }
      sanitized[key] = value;
    });

    if (kDebugMode) {
      debugPrint('VideoAnalytics: $name $sanitized');
    }
  }
}
