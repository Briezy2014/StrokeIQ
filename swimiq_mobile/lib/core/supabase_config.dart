import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads Supabase credentials from `.env` or `--dart-define` values.
class SupabaseConfig {
  static String get url {
    final fromEnv = dotenv.maybeGet('SUPABASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv;
    }

    const fromDefine = String.fromEnvironment('SUPABASE_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    throw StateError(
      'SUPABASE_URL is missing. Copy .env.example to .env or pass '
      '--dart-define=SUPABASE_URL=...',
    );
  }

  static String get anonKey {
    final fromEnv = dotenv.maybeGet('SUPABASE_ANON_KEY');
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv;
    }

    const fromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    throw StateError(
      'SUPABASE_ANON_KEY is missing. Copy .env.example to .env or pass '
      '--dart-define=SUPABASE_ANON_KEY=...',
    );
  }
}
