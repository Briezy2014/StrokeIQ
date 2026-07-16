import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/models/subscription_plan.dart';

void main() {
  test('coach access codes are validated before unlock', () {
    expect(SubscriptionCatalog.isCoachAccessCode('COACH-EVAL-14'), isTrue);
    expect(SubscriptionCatalog.isCoachAccessCode('coach-trial-30'), isTrue);
    expect(SubscriptionCatalog.isCoachAccessCode('WRONG-CODE'), isFalse);
    expect(SubscriptionCatalog.isCoachAccessCode(''), isFalse);
  });
}
