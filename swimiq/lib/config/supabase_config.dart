import 'env.dart';

/// Supabase connection settings — no committed secrets.
class SupabaseConfig {
  static String get url => Env.supabaseUrl;
  static String get anonKey => Env.supabaseAnonKey;
}
