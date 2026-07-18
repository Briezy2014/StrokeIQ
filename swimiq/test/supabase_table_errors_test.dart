import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/supabase_table_errors.dart';

void main() {
  test('detects missing swim_video_analyses table', () {
    const error = "PostgrestException(message: Could not find the table "
        "'public.swim_video_analyses' in the schema cache, code: PGRST205)";
    expect(
      SupabaseTableErrors.isMissingTable(error, tableName: 'swim_video_analyses'),
      isTrue,
    );
  });

  test('detects missing swim_videos.user_id column', () {
    const error =
        "PostgresException(message: Could not find the 'user_id' column of "
        "'swim_videos' in the schema cache, code: PGRST204, details: , hint: null)";
    expect(
      SupabaseTableErrors.isMissingColumn(
        error,
        columnName: 'user_id',
        tableName: 'swim_videos',
      ),
      isTrue,
    );
  });
}
