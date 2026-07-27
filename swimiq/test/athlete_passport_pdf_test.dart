import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/recruiting/athlete_passport_pdf.dart';
import 'package:swimiq/core/utils/passport_metrics.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/swim_schedule_entry.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  test('full Athlete Passport PDF includes status and Power Index sections',
      () async {
    final data = SwimmerData(
      raceLogs: const [],
      goals: const [],
      meetResults: [
        MeetResult(
          swimmerName: 'Aspyn',
          meetName: 'Spring Invite',
          event: '100 Butterfly',
          swimTime: 68.2,
          course: 'SCY',
          meetDate: DateTime(2026, 3, 1),
        ),
      ],
      schedules: [
        SwimScheduleEntry(
          swimmerName: 'Aspyn',
          scheduleType: SwimScheduleEntry.typeMeet,
          title: 'Summer Invite',
          scheduleDate: DateTime.now().add(const Duration(days: 5)),
          startTime: '8:30 AM',
        ),
      ],
      profile: SwimmerProfile(
        swimmerName: 'Aspyn',
        firstName: 'Aspyn',
        lastName: 'Briez',
        birthday: DateTime(2014, 6, 8),
        graduationYear: 2032,
        team: 'Central Ohio Aquatics',
        athleteNotes: SwimmerProfile.composeAthleteNotes(gender: 'Female'),
      ),
      motivationalStandards: testMotivationalCatalog,
    );

    final snapshot = data.passportSnapshot('Aspyn');
    final bytes = await AthletePassportPdf.buildBytes(
      snapshot: snapshot,
      profile: data.profile,
      displayName: 'Aspyn Briez',
    );

    expect(bytes.length, greaterThan(500));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');

    final content = _decompressedPdfText(bytes);
    for (final needle in [
      'ATHLETE',
      'PASSPORT',
      'Aspyn',
      'STATUS',
      'POWER',
      'INDEX',
      'TOP',
      'TIMES',
      'GOALS',
      'SWIMIQ',
    ]) {
      expect(content, contains(needle), reason: '$needle missing from PDF');
    }
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
    if (payloadStart < data.length && data[payloadStart] == 0x0D) {
      payloadStart++;
    }
    if (payloadStart < data.length && data[payloadStart] == 0x0A) {
      payloadStart++;
    }

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
