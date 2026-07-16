import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/gemini_swim_analysis_service.dart';
import 'app_providers.dart';

/// Live check against the deployed analyze-swim-video edge function.
final videoServerHealthProvider =
    FutureProvider<VideoAnalysisServerHealth>((ref) async {
  return ref.read(geminiSwimAnalysisServiceProvider).checkServerHealth();
});

bool isVideoServerStreamReady(VideoAnalysisServerHealth? health) {
  if (health == null || !health.ok) return false;
  final version = health.functionVersion ?? '';
  return version.contains('stream-v4') ||
      version.contains('stream-v5') ||
      version.contains('stream-v6') ||
      version.contains('stream-v7') ||
      version.contains('stream-v8');
}
