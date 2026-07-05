import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/ai_swim_analysis_service.dart';
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

final aiSwimAnalysisServiceProvider = Provider<AiSwimAnalysisService>(
  (ref) => AiSwimAnalysisService(),
);

final usaMotivationalStandardsCatalogProvider =
    FutureProvider<UsaMotivationalStandardsCatalog>(
  (ref) => UsaMotivationalStandardsCatalog.loadFromAssets(),
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
