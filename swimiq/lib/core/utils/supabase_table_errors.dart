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
    return 'Video history is temporarily unavailable. '
        'Please try again in a few minutes. '
        'If it keeps happening, email support@swimiqapp.com.';
  }

  static String missingSwimVideosUserIdMessage() {
    return 'Video upload needs a quick server update. '
        'Please try again shortly, or email support@swimiqapp.com.';
  }

  /// Customer-facing message when schedule/meet save fails against Supabase.
  static String scheduleSaveMessage(Object error) {
    if (isMissingTable(error, tableName: 'swim_schedules')) {
      return 'Upcoming meets need a quick database update. '
          'Email support@swimiqapp.com and we will turn on swim_schedules.';
    }
    if (isMissingColumn(error, tableName: 'swim_schedules')) {
      return 'Meet schedule fields need a quick server update. '
          'Please try again shortly, or email support@swimiqapp.com.';
    }
    final text = error.toString();
    if (text.toLowerCase().contains('row-level security') ||
        text.toLowerCase().contains('42501')) {
      return 'Could not save this meet (permission). '
          'Sign out, sign back in, and try again.';
    }
    if (text.toLowerCase().contains('null check operator') ||
        text.toLowerCase().contains('nullvalue')) {
      return 'Could not save this meet — a required field was missing. '
          'Add the meet name and try again.';
    }
    // Keep snackbars short and readable (avoid raw PostgrestException walls).
    final trimmed = text
        .replaceAll(RegExp(r'PostgrestException\(|PostgresException\('), '')
        .replaceAll(RegExp(r',\s*code:.*$'), '')
        .replaceAll(RegExp(r'^message:\s*', caseSensitive: false), '')
        .replaceAll(')', '')
        .trim();
    if (trimmed.isEmpty || trimmed.length > 160) {
      return 'Could not save this meet. Check your connection and try again.';
    }
    return 'Could not save this meet: $trimmed';
  }
}
