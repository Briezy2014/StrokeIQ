import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/models/subscription_plan.dart';
import 'package:swimiq/core/subscription/ambassador_catalog.dart';

void main() {
  test('coach access codes are validated before unlock', () {
    expect(SubscriptionCatalog.isCoachAccessCode('COACH-EVAL-14'), isTrue);
    expect(SubscriptionCatalog.isCoachAccessCode('coach-trial-30'), isTrue);
    expect(SubscriptionCatalog.isCoachAccessCode('WRONG-CODE'), isFalse);
    expect(SubscriptionCatalog.isCoachAccessCode(''), isFalse);
  });

  test('named ambassadors Ruslan and Nyah have unique codes and links', () {
    expect(AmbassadorCatalog.ruslan.code, 'AMB-RUSLAN');
    expect(AmbassadorCatalog.nyah.code, 'AMB-NYAH');
    expect(AmbassadorCatalog.ruslan.slug, 'ruslan');
    expect(AmbassadorCatalog.nyah.slug, 'nyah');
    expect(
      AmbassadorCatalog.ruslan.preferredShareUrl,
      'https://swimiqapp.com/?amb=AMB-RUSLAN&via=ruslan',
    );
    expect(
      AmbassadorCatalog.nyah.preferredShareUrl,
      'https://swimiqapp.com/?amb=AMB-NYAH&via=nyah',
    );
    expect(SubscriptionCatalog.isAmbassadorAccessCode('AMB-RUSLAN'), isTrue);
    expect(SubscriptionCatalog.isAmbassadorAccessCode('AMB-NYAH'), isTrue);
    expect(SubscriptionCatalog.isPromoAccessCode('AMBASSADOR-SWIMIQ'), isTrue);
  });

  test('promoCodeFromUri reads amb and via for named ambassadors', () {
    expect(
      SubscriptionCatalog.promoCodeFromUri(
        Uri.parse('https://swimiqapp.com/?amb=AMB-RUSLAN&via=ruslan'),
      ),
      'AMB-RUSLAN',
    );
    expect(
      SubscriptionCatalog.promoCodeFromUri(
        Uri.parse('https://swimiqapp.com/?via=nyah'),
      ),
      'AMB-NYAH',
    );
    expect(
      AmbassadorCatalog.referralSlugFromUri(
        Uri.parse('https://swimiqapp.com/?amb=AMB-NYAH&via=nyah'),
      ),
      'nyah',
    );
    expect(
      SubscriptionCatalog.promoCodeFromUri(
        Uri.parse('https://swimiqapp.com/?amb=WRONG'),
      ),
      isNull,
    );
  });
}
