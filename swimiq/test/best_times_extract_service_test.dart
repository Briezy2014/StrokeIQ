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

  test('combined failure message tells user how to fix deploy or Elite', () {
    final message = BestTimesExtractService.combinedFailureMessageForTest([
      'Elite: not running on http://127.0.0.1:8080',
      'Cloud extract-best-times: Failed to fetch',
    ]);
    expect(message, contains('DEPLOY-EXTRACT-BEST-TIMES.bat'));
    expect(message, contains('START-SWIMIQ-WITH-ELITE.bat'));
    expect(message.toLowerCase(), contains('gemini_api_key'));
  });

  test('elite timeout is long enough for Gemini photo reads', () {
    expect(
      BestTimesExtractService.eliteTimeout.inSeconds,
      greaterThanOrEqualTo(60),
    );
  });
}
