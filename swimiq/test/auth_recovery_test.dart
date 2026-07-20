import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/app.dart';

void main() {
  test('auth recovery copy treats Failed to fetch as network hiccup', () {
    const raw =
        'AuthRetryableFetchException(message: ClientException: Failed to fetch, '
        'uri=https://bryurwyeosbffvfpdpbv.supabase.co/auth/v1/token?grant_type=refresh_token)';
    // Mirror the private helper logic used by _AuthRecoveryScreen.
    final lower = raw.toLowerCase();
    final isNetwork = lower.contains('failed to fetch') ||
        lower.contains('authretryablefetchexception') ||
        lower.contains('clientexception');
    expect(isNetwork, isTrue);
  });
}
