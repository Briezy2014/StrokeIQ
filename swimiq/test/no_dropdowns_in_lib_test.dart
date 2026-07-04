import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/**/*.dart contains no DropdownButton widgets', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'Run from swimiq package root');

    final offenders = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      if (content.contains('DropdownButton') ||
          content.contains('DropdownMenuItem')) {
        offenders.add(entity.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Remove dropdown widgets from: ${offenders.join(', ')}',
    );
  });
}
