import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

  test('recruiting business card PDF embeds stat values in content stream', () async {
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

    final content = _decompressedPdfText(bytes);
    for (final needle in ['550', 'BB', '4.0', 'swimiq.app', 'Butterfly', 'GPA']) {
      expect(content, contains(needle), reason: '$needle missing from PDF stream');
    }
    expect(content, isNot(contains('1 1 1 rg f')));
  });
}

String _decompressedPdfText(List<int> bytes) {
  final data = Uint8List.fromList(bytes);
  final buffer = StringBuffer();
  final streamMarker = utf8.encode('stream');
  final endMarker = utf8.encode('endstream');

  var index = 0;
  while (index < data.length) {
    final streamStart = _indexOf(data, streamMarker, index);
    if (streamStart < 0) break;
    var payloadStart = streamStart + streamMarker.length;
    if (payloadStart < data.length && data[payloadStart] == 0x0D) payloadStart++;
    if (payloadStart < data.length && data[payloadStart] == 0x0A) payloadStart++;

    final streamEnd = _indexOf(data, endMarker, payloadStart);
    if (streamEnd < 0) break;

    final payload = data.sublist(payloadStart, streamEnd);
    try {
      final decoded = zlib.decode(payload);
      buffer.write(utf8.decode(decoded, allowMalformed: true));
      buffer.write('\n');
    } catch (_) {}

    index = streamEnd + endMarker.length;
  }

  return buffer.toString();
}

int _indexOf(Uint8List data, List<int> pattern, int start) {
  for (var i = start; i <= data.length - pattern.length; i++) {
    var matched = true;
    for (var j = 0; j < pattern.length; j++) {
      if (data[i + j] != pattern[j]) {
        matched = false;
        break;
      }
    }
    if (matched) return i;
  }
  return -1;
}
