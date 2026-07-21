import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/constants/app_constants.dart';

void main() {
  test('gemini analysis size cap matches edge function 100 MB', () {
    expect(AppConstants.maxGeminiVideoMb, 100);
    expect(AppConstants.maxGeminiVideoBytes, 100 * 1024 * 1024);
  });
}
