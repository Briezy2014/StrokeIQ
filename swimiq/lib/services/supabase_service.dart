import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Initializes and exposes the shared Supabase client.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase is not initialized. Call initialize() first.');
    }
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    if (!Env.isConfigured) {
      throw StateError(
        'Supabase credentials are not configured. '
        'Copy .env.example to .env or pass --dart-define values.',
      );
    }

    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _initialized = true;
  }
}
