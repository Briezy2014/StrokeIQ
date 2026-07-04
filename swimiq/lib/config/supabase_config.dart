/// Supabase connection settings.
///
/// Override at build time with `--dart-define`:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bryurwyeosbffvfpdpbv.supabase.co',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_Xzy-xAEqOM-0Nh3Ig7MiTg_n4986BvS',
  );
}
