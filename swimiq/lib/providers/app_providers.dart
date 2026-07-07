import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/subscription_plan.dart';
import '../core/services/ai_swim_analysis_service.dart';
import '../core/services/gemini_swim_analysis_service.dart';
import '../core/services/profile_photo_service.dart';
import '../core/services/swim_pose_analysis_service.dart';
import '../core/services/subscription_service.dart';
import '../core/services/usa_motivational_standards_catalog.dart';
import '../core/services/usa_standards_service.dart';
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
  static const addSession = 3;
  static const goals = 4;
  static const meetResults = 5;
  static const videoLab = 6;
  static const passport = 7;
}

final homeTabIndexProvider = StateProvider<int>((ref) => HomeTab.dashboard);

final aiSwimAnalysisServiceProvider = Provider<AiSwimAnalysisService>(
  (ref) => AiSwimAnalysisService(),
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

final profilePhotoServiceProvider = Provider<ProfilePhotoService>(
  (ref) => ProfilePhotoService(ref.watch(supabaseClientProvider)),
);

final subscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) => SubscriptionService(),
);

final subscriptionStateProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  SubscriptionNotifier.new,
);

class SubscriptionNotifier extends AsyncNotifier<SubscriptionState> {
  @override
  Future<SubscriptionState> build() async {
    final service = ref.read(subscriptionServiceProvider);
    final state = await service.load();
    if (!state.hasUsedTrial && !state.isTrialActive) {
      return service.startTrialIfEligible(state);
    }
    return state;
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
}
