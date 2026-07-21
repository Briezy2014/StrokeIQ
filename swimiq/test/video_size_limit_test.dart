import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/constants/app_constants.dart';

void main() {
  test('gemini analysis size cap matches edge function 25 MB', () {
    expect(AppConstants.maxGeminiVideoMb, 25);
    expect(AppConstants.maxGeminiVideoBytes, 25 * 1024 * 1024);
  });
}
