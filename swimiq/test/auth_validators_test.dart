import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('email rejects empty', () {
      expect(AuthValidators.email(''), isNotNull);
    });

    test('email rejects invalid format', () {
      expect(AuthValidators.email('not-an-email'), isNotNull);
    });

    test('email accepts valid address', () {
      expect(AuthValidators.email('swimmer@example.com'), isNull);
    });

    test('password rejects short values', () {
      expect(AuthValidators.password('123'), isNotNull);
    });

    test('password accepts valid length', () {
      expect(AuthValidators.password('secret1'), isNull);
    });

    test('confirmPassword rejects mismatch', () {
      expect(
        AuthValidators.confirmPassword('abc', 'def'),
        isNotNull,
      );
    });

    test('confirmPassword accepts match', () {
      expect(
        AuthValidators.confirmPassword('secret1', 'secret1'),
        isNull,
      );
    });
  });

  group('AuthErrorMapper', () {
    test('maps invalid credentials', () {
      expect(
        AuthErrorMapper.fromException(
          Exception('Invalid login credentials'),
        ),
        'Incorrect email or password.',
      );
    });
  });
}
