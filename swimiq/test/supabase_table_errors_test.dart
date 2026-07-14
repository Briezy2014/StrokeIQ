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
}
