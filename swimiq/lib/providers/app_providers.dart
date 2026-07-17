import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/subscription_plan.dart';
import '../core/services/ai_swim_analysis_service.dart';
import '../core/services/gemini_college_match_service.dart';
import '../core/services/gemini_swim_analysis_service.dart';
import '../core/services/pending_coach_code_storage.dart';
import '../core/services/profile_photo_service.dart';
import '../core/services/swim_pose_analysis_service.dart';
import '../core/services/stripe_checkout_support.dart';
import '../core/services/stripe_checkout_service.dart';
import '../core/services/subscription_service.dart';
import '../core/services/usa_motivational_standards_catalog.dart';
import '../core/services/usa_standards_service.dart';
import '../core/services/video_analytics_service.dart';
import '../core/services/video_engine_v2_service.dart';
import '../core/services/video_storage_service.dart';
import '../data/repositories/swimiq_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final swimIqRepositoryProvider = Provider<SwimIqRepository>(
  (ref) => SwimIqRepository(ref.watch(supabaseClientProvider)),
);

final activeSwimmerProvider = StateProvider<String?>((ref) => null);

/// Bottom-nav tab indices for [HomeScreen].
abstract final class HomeTab {
  static const dashboard = 0;
  static const personalBests = 1;
  static const trainingLog = 2;
  static const goals = 3;
  static const videoLab = 4;
  static const passport = 5;
}

final homeTabIndexProvider = StateProvider<int>((ref) => HomeTab.dashboard);

/// 0 = training sessions, 1 = meets & results inside [TrainingLogScreen].
final trainingLogSegmentProvider = StateProvider<int>((ref) => 0);

final aiSwimAnalysisServiceProvider = Provider<AiSwimAnalysisService>(
  (ref) => AiSwimAnalysisService(),
);

final geminiCollegeMatchServiceProvider = Provider<GeminiCollegeMatchService>(
  (ref) => GeminiCollegeMatchService(ref.watch(supabaseClientProvider)),
);

final geminiSwimAnalysisServiceProvider = Provider<GeminiSwimAnalysisService>(
  (ref) => GeminiSwimAnalysisService(ref.watch(supabaseClientProvider)),
);

final swimPoseAnalysisServiceProvider = Provider<SwimPoseAnalysisService>(
  (ref) => SwimPoseAnalysisService(),
);

final usaMotivationalStandardsCatalogProvider =
    FutureProvider<UsaMotivationalStandardsCatalog>(
  (ref) => UsaMotivationalStandardsCatalog.loadFromAssets(),
);

final usaStandardsServiceProvider = Provider<UsaStandardsService>(
  (ref) => UsaStandardsService(),
);

final videoStorageServiceProvider = Provider<VideoStorageService>(
  (ref) => VideoStorageService(
    ref.watch(supabaseClientProvider),
    ref.watch(swimIqRepositoryProvider),
  ),
);

final videoAnalyticsServiceProvider = Provider<VideoAnalyticsService>(
  (ref) => const VideoAnalyticsService(),
);

final videoEngineV2ServiceProvider = Provider<VideoEngineV2Service>(
  (ref) => VideoEngineV2Service(
    supabase: ref.watch(supabaseClientProvider),
  ),
);

final profilePhotoServiceProvider = Provider<ProfilePhotoService>(
  (ref) => ProfilePhotoService(ref.watch(supabaseClientProvider)),
);

final subscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) => SubscriptionService(client: ref.watch(supabaseClientProvider)),
);

final stripeCheckoutServiceProvider = Provider<StripeCheckoutService>(
  (ref) => StripeCheckoutService(ref.watch(supabaseClientProvider)),
);

final subscriptionStateProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  SubscriptionNotifier.new,
);

class SubscriptionNotifier extends AsyncNotifier<SubscriptionState> {
  @override
  Future<SubscriptionState> build() async {
    final service = ref.read(subscriptionServiceProvider);
    var state = await service.load();
    if (!state.isDemoMaster &&
        !state.hasActiveServerPlan &&
        !state.hasUsedTrial &&
        !state.isTrialActive) {
      state = await service.startTrialIfEligible(state);
    }
    return state;
  }

  Future<void> refreshFromServer() async {
    final service = ref.read(subscriptionServiceProvider);
    state = AsyncData(await service.refreshFromServer());
  }

  Future<String> startStripeCheckout(
    SubscriptionTier tier,
    BillingCycle cycle,
  ) async {
    final checkout = ref.read(stripeCheckoutServiceProvider);
    return checkout.startCheckout(
      tier: tier,
      billingCycle: cycle,
      successUrl: StripeCheckoutUrls.successUrl(),
      cancelUrl: StripeCheckoutUrls.cancelUrl(),
    );
  }

  Future<void> selectPlan(SubscriptionTier tier, BillingCycle cycle) async {
    final service = ref.read(subscriptionServiceProvider);
    final current = state.value ?? await service.load();
    state = AsyncData(
      await service.selectPlan(
        current: current,
        tier: tier,
        billingCycle: cycle,
      ),
    );
  }

  Future<String?> redeemCoachCode(String code) async {
    try {
      final service = ref.read(subscriptionServiceProvider);
      final current = state.value ?? await service.load();
      state = AsyncData(await service.redeemCoachCode(current, code));
      return null;
    } on FormatException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    }
  }

  Future<void> recordCoachAiAnalysis() async {
    final service = ref.read(subscriptionServiceProvider);
    final current = state.value ?? await service.load();
    state = AsyncData(await service.recordCoachAiAnalysis(current));
  }

  Future<String?> redeemPendingCoachCodeIfAny() async {
    final pending = await PendingCoachCodeStorage.take();
    if (pending == null || pending.isEmpty) return null;
    return redeemCoachCode(pending);
  }
}
