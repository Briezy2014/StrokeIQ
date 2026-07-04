/// Loads Supabase credentials from environment variables.
///
/// Local development: copy `.env.example` to `.env` and fill in values.
/// Production builds: pass `--dart-define=SUPABASE_URL=...` and
/// `--dart-define=SUPABASE_ANON_KEY=...`.
class Env {
  Env._();

  static const _urlDefine = String.fromEnvironment('SUPABASE_URL');
  static const _keyDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String? _urlFromDotenv;
  static String? _keyFromDotenv;

  /// Call once after [dotenv.load] in main().
  static void loadFromDotenv(Map<String, String> env) {
    _urlFromDotenv = env['SUPABASE_URL'];
    _keyFromDotenv = env['SUPABASE_ANON_KEY'];
  }

  static String get supabaseUrl {
    final value = _urlFromDotenv ?? _urlDefine;
    if (value.isEmpty) {
      throw StateError(
        'SUPABASE_URL is not set. Copy .env.example to .env or use --dart-define.',
      );
    }
    return value;
  }

  static String get supabaseAnonKey {
    final value = _keyFromDotenv ?? _keyDefine;
    if (value.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY is not set. Copy .env.example to .env or use --dart-define.',
      );
    }
    return value;
  }

  static bool get isConfigured {
    final url = _urlFromDotenv ?? _urlDefine;
    final key = _keyFromDotenv ?? _keyDefine;
    return url.isNotEmpty && key.isNotEmpty;
  }
}
