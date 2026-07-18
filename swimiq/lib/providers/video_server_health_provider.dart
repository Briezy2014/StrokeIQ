import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/feature_flags.dart';
import '../core/services/gemini_swim_analysis_service.dart';
import '../core/services/video_engine_v2_service.dart';
import 'app_providers.dart';

/// Live check against Elite `/health` when V2 is on; otherwise legacy Gemini.
final videoServerHealthProvider =
    FutureProvider<VideoAnalysisServerHealth>((ref) async {
  if (FeatureFlags.videoEngineV2Enabled) {
    final elite = await ref.read(videoEngineV2ServiceProvider).checkHealth();
    return VideoAnalysisServerHealth(
      ok: elite.reachable &&
          elite.mediaToolsReady &&
          elite.storageConfigured,
      message: elite.message,
      functionVersion: elite.engineVersion,
      modelProbeOk: elite.mediaToolsReady,
    );
  }
  return ref.read(geminiSwimAnalysisServiceProvider).checkServerHealth();
});

/// Pollable Elite-only health for banners / setup.
final eliteServerHealthProvider =
    FutureProvider<EliteServerHealth>((ref) async {
  return ref.read(videoEngineV2ServiceProvider).checkHealth();
});

bool isVideoServerStreamReady(VideoAnalysisServerHealth? health) {
  if (health == null || !health.ok) return false;
  final version = health.functionVersion ?? '';
  if (FeatureFlags.videoEngineV2Enabled) {
    return version.contains('elite') ||
        version.contains('elote') ||
        version.contains('video_engine');
  }
  return version.contains('sync-v9') ||
      version.contains('stream-v4') ||
      version.contains('stream-v5') ||
      version.contains('stream-v6') ||
      version.contains('stream-v7') ||
      version.contains('stream-v8');
}
