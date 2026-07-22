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
  // Public website customers must never see local .bat / 127.0.0.1 setup copy.
  // Cloud coaching is the website path; local Elite is optional for developers.
  if (FeatureFlags.videoEngineV2Enabled) {
    if (Env.isPublicHostedWeb) {
      return const VideoAnalysisServerHealth(
        ok: true,
        message: 'Cloud AI coaching is ready on this website.',
        functionVersion: 'cloud-coaching',
        modelProbeOk: true,
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
