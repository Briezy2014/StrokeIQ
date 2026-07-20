import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/best_times_extract_service.dart';

void main() {
  test('extract exceptions carry actionable codes', () {
    final edge = BestTimesExtractException(
      'Photo import is temporarily unavailable. '
      'Please try again later or enter times manually.',
      errorCode: 'EDGE_FAILED',
    );
    expect(edge.message, contains('temporarily unavailable'));
    expect(edge.errorCode, 'EDGE_FAILED');

    final elite = BestTimesExtractException(
      'Could not reach the Elite server to read this photo.',
      errorCode: 'SERVER_UNAVAILABLE',
    );
    expect(elite.errorCode, 'SERVER_UNAVAILABLE');
  });
}
