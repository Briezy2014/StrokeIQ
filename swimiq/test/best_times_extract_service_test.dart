import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/best_times_extract_service.dart';

void main() {
  test('extract exceptions carry actionable codes', () {
    final edge = BestTimesExtractException(
      'GEMINI_API_KEY is not configured in Supabase Edge Function secrets.',
      errorCode: 'EDGE_FAILED',
    );
    expect(edge.message, contains('GEMINI_API_KEY'));
    expect(edge.errorCode, 'EDGE_FAILED');

    final elite = BestTimesExtractException(
      'Could not reach the Elite server to read this photo.',
      errorCode: 'SERVER_UNAVAILABLE',
    );
    expect(elite.errorCode, 'SERVER_UNAVAILABLE');
  });
}
