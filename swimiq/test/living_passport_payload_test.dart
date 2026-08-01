import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/recruiting/living_passport_payload.dart';

void main() {
  test('encode/decode keeps Power Index chart fields', () {
    const original = LivingPassportPayload(
      displayName: 'Aspyn Briez',
      swimIqScore: 993,
      highestCut: 'BB',
      readiness: 'Race ready',
      nextMeet: 'Time trial — 100 Fly SCY',
      powerIndexLine: '65 / 100 · Competitive',
      topTimes: ['100 Fly SCY · 1:12.00', '200 Fly LCM · 3:07.00'],
      latestTechniquePriorities: ['Longer streamline into the wall'],
      generatedAtIso: '2026-08-01T12:00:00.000Z',
      powerIndexScore: 65,
      powerIndexLabel: 'Competitive',
      powerFactors: [
        LivingPassportPowerFactor(
          id: 'cuts',
          label: 'USA cuts',
          score: 70,
          weightPercent: 40,
        ),
        LivingPassportPowerFactor(
          id: 'college',
          label: 'College fit',
          score: 55,
          weightPercent: 20,
        ),
      ],
      strongestEvent: '100 Fly SCY',
      currentFocus: 'Butterfly race pace',
      usaStandardsSummary: 'Highest cut achieved: BB.',
    );

    final roundTrip = LivingPassportPayload.tryDecode(original.encode());
    expect(roundTrip, isNotNull);
    expect(roundTrip!.displayName, 'Aspyn Briez');
    expect(roundTrip.powerIndexScore, 65);
    expect(roundTrip.powerIndexLabel, 'Competitive');
    expect(roundTrip.powerFactors, hasLength(2));
    expect(roundTrip.powerFactors.first.id, 'cuts');
    expect(roundTrip.strongestEvent, '100 Fly SCY');
    expect(roundTrip.currentFocus, 'Butterfly race pace');
    expect(roundTrip.resolvedPowerIndexScore, 65);
  });

  test('shareUrl for swimiqapp.com forces http Living Passport ?lp=', () {
    const payload = LivingPassportPayload(
      displayName: 'Aspyn Briez',
      swimIqScore: 993,
      highestCut: 'BB',
      readiness: 'Race ready',
      nextMeet: 'None scheduled',
      powerIndexLine: '65 / 100 · Competitive',
      topTimes: const [],
      latestTechniquePriorities: const [],
      generatedAtIso: '2026-08-01T12:00:00.000Z',
    );

    final url = payload.shareUrl(
      base: Uri.parse('https://www.swimiqapp.com/passport'),
    );
    expect(url.startsWith('http://swimiqapp.com/?lp='), isTrue);
    expect(url.contains('https://'), isFalse);
  });

  test('old payloads without chart fields still decode', () {
    const legacy = LivingPassportPayload(
      displayName: 'Aspyn Briez',
      swimIqScore: 900,
      highestCut: 'B',
      readiness: 'Building',
      nextMeet: 'None scheduled',
      powerIndexLine: '50 / 100 · Developing',
      topTimes: const ['50 Free SCY · 28.00'],
      latestTechniquePriorities: const [],
      generatedAtIso: '2026-07-01T12:00:00.000Z',
    );
    final decoded = LivingPassportPayload.tryDecode(legacy.encode());
    expect(decoded, isNotNull);
    expect(decoded!.powerFactors, isEmpty);
    expect(decoded.resolvedPowerIndexScore, 50);
    expect(decoded.resolvedPowerIndexLabel, contains('Developing'));
  });
}
