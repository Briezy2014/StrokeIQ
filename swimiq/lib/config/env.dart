/// Loads client-safe configuration from environment variables.
///
/// Local development: copy `.env.example` to `.env` and fill in values.
/// Production builds: pass `--dart-define=...` for the same keys.
///
/// Never load Gemini API keys or Supabase service-role keys here.
class Env {
  Env._();

  static const _urlDefine = String.fromEnvironment('SUPABASE_URL');
  static const _keyDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _analysisApiDefine =
      String.fromEnvironment('ANALYSIS_API_BASE_URL');
  static const _videoEngineV2Define =
      String.fromEnvironment('VIDEO_ENGINE_V2', defaultValue: 'false');
  static const _videoEngineV2AllowlistDefine =
      String.fromEnvironment('VIDEO_ENGINE_V2_ALLOWLIST');
  static const _videoEngineV2DualRunDefine =
      String.fromEnvironment('VIDEO_ENGINE_V2_DUAL_RUN', defaultValue: 'false');

  static String? _urlFromDotenv;
  static String? _keyFromDotenv;
  static String? _analysisApiFromDotenv;
  static String? _videoEngineV2FromDotenv;
  static String? _videoEngineV2AllowlistFromDotenv;
  static String? _videoEngineV2DualRunFromDotenv;

  static void loadFromDotenv(Map<String, String> env) {
    _urlFromDotenv = env['SUPABASE_URL'];
    _keyFromDotenv = env['SUPABASE_ANON_KEY'];
    _analysisApiFromDotenv = env['ANALYSIS_API_BASE_URL'];
    _videoEngineV2FromDotenv = env['VIDEO_ENGINE_V2'];
    _videoEngineV2AllowlistFromDotenv = env['VIDEO_ENGINE_V2_ALLOWLIST'];
    _videoEngineV2DualRunFromDotenv = env['VIDEO_ENGINE_V2_DUAL_RUN'];
  }

  static String get supabaseUrl {
    final value = _preferNonEmpty(_urlFromDotenv, _urlDefine);
    if (value.isEmpty) {
      throw StateError(
        'SUPABASE_URL is not set. Copy .env.example to .env or use --dart-define.',
      );
    }
    return value;
  }

  static String get supabaseAnonKey {
    final value = _preferNonEmpty(_keyFromDotenv, _keyDefine);
    if (value.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY is not set. Copy .env.example to .env or use --dart-define.',
      );
    }
    return value;
  }

  /// Base URL for the Video Engine V2 FastAPI service (no trailing slash).
  static String get analysisApiBaseUrl {
    final raw = _preferNonEmpty(_analysisApiFromDotenv, _analysisApiDefine);
    // 127.0.0.1 avoids Windows localhost → IPv6 (::1) misses when uvicorn is IPv4-only.
    if (raw.isEmpty) return 'http://127.0.0.1:8080';
    final normalized = raw
        .replaceAll('http://localhost:', 'http://127.0.0.1:')
        .replaceAll('https://localhost:', 'https://127.0.0.1:');
    return normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }

  static bool get videoEngineV2 {
    return _parseBool(
      _preferNonEmpty(_videoEngineV2FromDotenv, _videoEngineV2Define),
    );
  }

  /// Comma-separated emails allowed to use V2 when set. Empty = all users when V2 on.
  static List<String> get videoEngineV2Allowlist {
    final raw = _preferNonEmpty(
      _videoEngineV2AllowlistFromDotenv,
      _videoEngineV2AllowlistDefine,
    );
    if (raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  /// When true, legacy Gemini path remains available alongside V2.
  static bool get videoEngineV2DualRun {
    return _parseBool(
      _preferNonEmpty(
        _videoEngineV2DualRunFromDotenv,
        _videoEngineV2DualRunDefine,
      ),
    );
  }

  static bool get isConfigured {
    final url = _preferNonEmpty(_urlFromDotenv, _urlDefine);
    final key = _preferNonEmpty(_keyFromDotenv, _keyDefine);
    return url.isNotEmpty && key.isNotEmpty;
  }

  /// Prefer a non-empty dotenv value; otherwise fall back to dart-define.
  static String _preferNonEmpty(String? fromDotenv, String fromDefine) {
    final a = fromDotenv?.trim() ?? '';
    if (a.isNotEmpty) return a;
    return fromDefine.trim();
  }

  static bool _parseBool(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    return value == 'true' || value == '1' || value == 'yes' || value == 'on';
  }
}
