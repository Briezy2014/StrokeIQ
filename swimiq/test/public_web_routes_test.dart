import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/web/public_web_routes.dart';

void main() {
  group('PublicWebRoute.fromUri', () {
    test('delete-account query param', () {
      expect(
        PublicWebRoute.fromUri(Uri.parse('https://swimiqapp.com/?page=delete-account')),
        PublicWebRoute.deleteAccount,
      );
    });

    test('privacy query param', () {
      expect(
        PublicWebRoute.fromUri(Uri.parse('https://swimiqapp.com/?page=privacy')),
        PublicWebRoute.privacy,
      );
    });

    test('delete-account path', () {
      expect(
        PublicWebRoute.fromUri(Uri.parse('https://swimiqapp.com/delete-account.html')),
        PublicWebRoute.deleteAccount,
      );
    });

    test('home path is not public', () {
      expect(
        PublicWebRoute.fromUri(Uri.parse('https://swimiqapp.com/')),
        isNull,
      );
    });
  });
}
