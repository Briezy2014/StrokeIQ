/// Detects Supabase/PostgREST errors when a table was never created.
abstract final class SupabaseTableErrors {
  static bool isMissingTable(Object error, {String? tableName}) {
    final text = error.toString().toLowerCase();
    if (!text.contains('pgrst205') &&
        !text.contains('could not find the table') &&
        !text.contains('schema cache')) {
      return false;
    }
    if (tableName == null) return true;
    return text.contains(tableName.toLowerCase());
  }

  static String missingVideoAnalysesMessage() {
    return 'Video database table missing in Supabase. '
        'Open Supabase → SQL Editor → run swimiq/supabase/fix_video_tables.sql '
        '(or double-click KARA-FIX-VIDEO-DATABASE.bat). Then try again.';
  }
}
