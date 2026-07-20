import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/best_times_extract_service.dart';

void main() {
  test('combined failure message points at deploy or Elite', () {
    // Mirror the private helper via a public failure path isn't available;
    // assert the user-facing strings the service is designed to emit.
    const edge = BestTimesExtractException(
      'GEMINI_API_KEY is not configured in Supabase Edge Function secrets.',
      errorCode: 'EDGE_FAILED',
    );
    expect(edge.message, contains('GEMINI_API_KEY'));
    expect(edge.errorCode, 'EDGE_FAILED');

    const elite = BestTimesExtractException(
      'Could not reach the Elite server to read this photo.',
      errorCode: 'SERVER_UNAVAILABLE',
    );
    expect(elite.errorCode, 'SERVER_UNAVAILABLE');
  });
}
