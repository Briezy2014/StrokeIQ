import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../config/feature_flags.dart';
import '../core/services/gemini_swim_analysis_service.dart';
import '../core/services/video_engine_v2_service.dart';
import 'app_providers.dart';

/// Live check against Elite `/health` when V2 is on; otherwise legacy Gemini.
///
/// Auto-refreshes every few seconds while not ready so a late-starting Elite
/// server turns the banner green without a manual Recheck click.
final videoServerHealthProvider =
    FutureProvider.autoDispose<VideoAnalysisServerHealth>((ref) async {
  // Public website cannot reach a laptop Elite server. Never fake "ready".
  // When V2 is on for a public host, report not ready unless a real remote
  // ANALYSIS_API_BASE_URL (non-localhost) is configured and healthy.
  if (FeatureFlags.videoEngineV2Enabled) {
    if (Env.isPublicHostedWeb && Env.analysisApiBaseUrlIsLocalhost) {
      return const VideoAnalysisServerHealth(
        ok: false,
        message:
            'Elite analysis runs on SwimIQ localhost for now. '
            'On this website, Analyze uses cloud coaching when Elite is off — '
            'or open SwimIQ on this PC with START-SWIMIQ-WITH-ELITE.bat.',
        functionVersion: 'public-web-no-local-elite',
        modelProbeOk: false,
      );
    }
    final elite = await ref.read(videoEngineV2ServiceProvider).checkHealth();
    final ready = elite.reachable &&
        elite.mediaToolsReady &&
        elite.storageConfigured;
    if (!ready) {
      final timer = Timer(const Duration(seconds: 3), () {
        ref.invalidateSelf();
      });
      // Cancel on dispose so we never invalidate after teardown (Riverpod 2.x).
      ref.onDispose(timer.cancel);
    }
    return VideoAnalysisServerHealth(
      ok: ready,
      message: elite.message,
      functionVersion: elite.engineVersion,
      modelProbeOk: elite.mediaToolsReady,
    );
  }
  return ref.read(geminiSwimAnalysisServiceProvider).checkServerHealth();
});

/// Pollable Elite-only health for banners / setup.
final eliteServerHealthProvider =
    FutureProvider.autoDispose<EliteServerHealth>((ref) async {
  final health = await ref.read(videoEngineV2ServiceProvider).checkHealth();
  final ready = health.reachable &&
      health.mediaToolsReady &&
      health.storageConfigured;
  if (!ready && !Env.isPublicHostedWeb) {
    final timer = Timer(const Duration(seconds: 3), () {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
  return health;
});

bool isVideoServerStreamReady(VideoAnalysisServerHealth? health) {
  if (health == null || !health.ok) return false;
  final version = health.functionVersion ?? '';
  if (FeatureFlags.videoEngineV2Enabled) {
    if (version.contains('public-web-no-local-elite')) return false;
    return version.contains('elite') ||
        version.contains('elote') ||
        version.contains('video_engine') ||
        version.contains('cloud-coaching');
  }
  return version.contains('sync-v9') ||
      version.contains('sync-v10') ||
      version.contains('sync-v11') ||
      version.contains('sync-v12') ||
      version.contains('stream-v4') ||
      version.contains('stream-v5') ||
      version.contains('stream-v6') ||
      version.contains('stream-v7') ||
      version.contains('stream-v8');
}
