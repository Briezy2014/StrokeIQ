import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/recruiting/recruiting_business_card_pdf.dart';

void main() {
  test('recruiting business card PDF generates wallet-sized bytes', () async {
    final bytes = await RecruitingBusinessCardPdf.buildBytes(
      displayName: 'Aspyn Briezy',
      swimIqScore: 550,
      highestCut: 'BB',
      team: 'Central Ohio Aquatics',
      gpa: '4.0',
      website: 'https://swimiq.app/aspyn',
      topEvents: const [
        '200 Butterfly 3:10.00 (LCM)',
        '100 Butterfly 1:02.3 (SCY)',
      ],
      graduationYear: 2032,
      usaSwimmingId: 'AB1234E5F',
    );

    expect(bytes.length, greaterThan(400));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
