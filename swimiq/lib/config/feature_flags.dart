import 'env.dart';

/// Client feature flags for Video Engine cutover.
abstract final class FeatureFlags {
  static const videoEngineV2 = 'video_engine_v2';
  static const videoEngineLegacy = 'video_engine_legacy';

  static bool get videoEngineV2Enabled => Env.videoEngineV2;

  /// Legacy Gemini path stays on when V2 is off, or when dual-run is enabled.
  static bool get videoEngineLegacyEnabled =>
      !videoEngineV2Enabled || Env.videoEngineV2DualRun;

  /// Allowlist gate for V2 UI. Empty allowlist + V2 on → all users allowed.
  static bool isVideoEngineV2AllowedForEmail(String? email) {
    if (!videoEngineV2Enabled) return false;
    final allowlist = Env.videoEngineV2Allowlist;
    if (allowlist.isEmpty) return true;
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return allowlist.contains(normalized);
  }
}
