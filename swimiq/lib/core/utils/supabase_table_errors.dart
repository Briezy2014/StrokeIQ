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

  /// PGRST204 — request referenced a column PostgREST does not know yet.
  static bool isMissingColumn(Object error, {String? columnName, String? tableName}) {
    final text = error.toString().toLowerCase();
    final looksMissing = text.contains('pgrst204') ||
        (text.contains('could not find the') && text.contains('column'));
    if (!looksMissing) return false;
    if (columnName != null && !text.contains(columnName.toLowerCase())) {
      return false;
    }
    if (tableName != null && !text.contains(tableName.toLowerCase())) {
      return false;
    }
    return true;
  }

  static String missingVideoAnalysesMessage() {
    return 'Video database table missing in Supabase. '
        'Open Supabase → SQL Editor → run swimiq/supabase/fix_video_tables.sql '
        '(or double-click FIX-VIDEO-DATABASE.bat / KARA-FIX-VIDEO-DATABASE.bat). Then try again.';
  }

  static String missingSwimVideosUserIdMessage() {
    return 'Video upload needs a database update. '
        'Open FIX-VIDEO-UPLOAD-NOW.txt and paste the SQL into Supabase → SQL Editor → Run. '
        'Then upload again.';
  }
}
