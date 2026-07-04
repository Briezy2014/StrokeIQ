import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

/// Provides the shared Supabase client after [Supabase.initialize].
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Initializes Supabase before the app starts.
Future<void> initializeSupabase() async {
  if (!SupabaseConfig.isConfigured) {
    throw StateError(
      'Supabase is not configured. Pass --dart-define-from-file=supabase.env.json '
      'when running or building the app.',
    );
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}
