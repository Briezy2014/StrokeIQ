/// How Flutter links Supabase Auth users to existing swimmer data tables.
///
/// **No schema changes required.** The existing `swimmer` / `swimmer_name`
/// text columns are reused as the per-user data key.
///
/// Strategy:
/// - The authenticated Supabase user ID (`auth.users.id`) is stored in the
///   existing `swimmer` column on `race_logs`, `goals`, and `meet_results`.
/// - The same value is stored in `swimmers.swimmer_name` for the Athlete Passport.
/// - On first sign-in, a minimal swimmer profile row is created automatically.
///
/// This keeps the Streamlit schema intact while isolating each mobile user's data.
/// Streamlit sessions that used free-text swimmer names remain separate unless
/// the same UUID key is used intentionally.
///
/// Future improvement (will be proposed before implementation):
/// - Add optional `user_id uuid` columns and RLS policies for server-side security.

library;
