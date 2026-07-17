import '../core/constants/demo_account_constants.dart';
import '../core/constants/master_account_constants.dart';
import '../core/services/subscription_service.dart';
import '../core/subscription/subscription_capabilities.dart';
import 'env.dart';

/// Client feature flags for Video Engine cutover.
abstract final class FeatureFlags {
  static const videoEngineV2 = 'video_engine_v2';
  static const videoEngineLegacy = 'video_engine_legacy';

  static bool get videoEngineV2Enabled => Env.videoEngineV2;

  /// Legacy Gemini path only when V2 is off, or dual-run is explicitly enabled.
  /// When V2 is on and dual-run is off, the old Video Lab analyze path is hidden.
  static bool get videoEngineLegacyEnabled =>
      !videoEngineV2Enabled || Env.videoEngineV2DualRun;

  /// Built-in accounts that always get Elite Video Lab when V2 is on.
  static bool isBuiltInEliteVideoAccount(String? email) {
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return normalized == MasterAccountConstants.email.toLowerCase() ||
        normalized == DemoAccountConstants.email.toLowerCase();
  }

  /// Allowlist gate for V2 UI. Empty allowlist + V2 on → all users allowed.
  static bool isVideoEngineV2AllowedForEmail(String? email) {
    if (!videoEngineV2Enabled) return false;
    if (isBuiltInEliteVideoAccount(email)) return true;
    final allowlist = Env.videoEngineV2Allowlist;
    if (allowlist.isEmpty) return true;
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return allowlist.contains(normalized);
  }

  /// Elite Video Lab (V2) for master/demo, allowlisted emails, and anyone who
  /// already has Elite AI access (3-day trial, coach peek, paid Elite).
  static bool isVideoEngineV2Allowed({
    String? email,
    SubscriptionState? subscription,
  }) {
    if (!videoEngineV2Enabled) return false;
    if (isVideoEngineV2AllowedForEmail(email)) return true;
    if (subscription != null &&
        SubscriptionCapabilities.canRunSwimIqAiAnalysis(subscription)) {
      return true;
    }
    return false;
  }
}
