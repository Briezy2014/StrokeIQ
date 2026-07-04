import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/swimiq_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final swimIqRepositoryProvider = Provider<SwimIqRepository>(
  (ref) => SwimIqRepository(ref.watch(supabaseClientProvider)),
);

final activeSwimmerProvider = StateProvider<String?>((ref) => null);
