import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/**/*.dart contains no DropdownButton widgets', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'Run from swimiq package root');

    final allowedDropdownFiles = {
      'lib/screens/training_log/training_log_screen.dart',
    };

    final offenders = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowedDropdownFiles.any(normalized.endsWith)) continue;
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
