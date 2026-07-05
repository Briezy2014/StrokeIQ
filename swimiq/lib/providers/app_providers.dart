import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/ai_swim_analysis_service.dart';
import '../core/services/gemini_swim_analysis_service.dart';
import '../core/services/profile_photo_service.dart';
import '../core/services/swim_pose_analysis_service.dart';
import '../core/services/usa_standards_service.dart';
import '../core/services/video_storage_service.dart';
import '../data/repositories/swimiq_repository.dart';
import 'usa_standards_catalog_provider.dart';

export 'usa_standards_catalog_provider.dart';

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
  static const meetResults = 4;
  static const passport = 5;
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

final usaStandardsServiceProvider = Provider<UsaStandardsService>(
  (ref) => UsaStandardsService(ref.watch(swimIqRepositoryProvider)),
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
