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
  // Always probe local Elite (including swimiqapp.com). Chrome can reach
  // 127.0.0.1:8080 when Elite is running on this PC (CORS + private-network).
  if (FeatureFlags.videoEngineV2Enabled) {
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
    final hostedHint = Env.isPublicHostedWeb && !ready
        ? ' Start START-SWIMIQ-WITH-ELITE.bat on this PC, leave Elite open, then Recheck.'
        : '';
    return VideoAnalysisServerHealth(
      ok: ready,
      message: '${elite.message}$hostedHint',
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
