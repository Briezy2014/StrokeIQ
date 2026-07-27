import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/models/subscription_plan.dart';

void main() {
  test('coach access codes are validated before unlock', () {
    expect(SubscriptionCatalog.isCoachAccessCode('COACH-EVAL-14'), isTrue);
    expect(SubscriptionCatalog.isCoachAccessCode('coach-trial-30'), isTrue);
    expect(SubscriptionCatalog.isCoachAccessCode('WRONG-CODE'), isFalse);
    expect(SubscriptionCatalog.isCoachAccessCode(''), isFalse);
  });

  test('ambassador code and share link are wired', () {
    expect(
      SubscriptionCatalog.isAmbassadorAccessCode('AMBASSADOR-SWIMIQ'),
      isTrue,
    );
    expect(
      SubscriptionCatalog.isAmbassadorAccessCode('ambassador-swimiq'),
      isTrue,
    );
    expect(SubscriptionCatalog.isPromoAccessCode('AMBASSADOR-SWIMIQ'), isTrue);
    expect(SubscriptionCatalog.isPromoAccessCode('COACH-EVAL-14'), isTrue);
    expect(SubscriptionCatalog.isPromoAccessCode('NOPE'), isFalse);
    expect(
      SubscriptionCatalog.ambassadorShareUrl,
      'https://swimiqapp.com/?amb=AMBASSADOR-SWIMIQ',
    );
  });

  test('promoCodeFromUri reads amb and ref query params', () {
    expect(
      SubscriptionCatalog.promoCodeFromUri(
        Uri.parse('https://swimiqapp.com/?amb=AMBASSADOR-SWIMIQ'),
      ),
      'AMBASSADOR-SWIMIQ',
    );
    expect(
      SubscriptionCatalog.promoCodeFromUri(
        Uri.parse('https://swimiqapp.com/?ref=coach-eval-14'),
      ),
      'COACH-EVAL-14',
    );
    expect(
      SubscriptionCatalog.promoCodeFromUri(
        Uri.parse('https://swimiqapp.com/?amb=WRONG'),
      ),
      isNull,
    );
  });
}
