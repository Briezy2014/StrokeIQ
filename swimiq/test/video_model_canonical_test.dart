import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/data/models/video_models.dart';

void main() {
  group('Video Lab canonical models', () {
    test('SwimVideo.id and SwimVideoAnalysis.swimVideoId are String? UUIDs', () {
      const video = SwimVideo(
        id: 'b526aa2a-c18f-451b-b8f0-e80947d50c20',
        swimmer: 'Aspyn',
        storagePath: 'Aspyn/test.mp4',
      );
      const analysis = SwimVideoAnalysis(
        id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        swimVideoId: 'b526aa2a-c18f-451b-b8f0-e80947d50c20',
        swimmer: 'Aspyn',
        summary: 'Test',
        strengths: 'Kick',
        improvements: 'Breath',
        techniqueScore: 80,
        paceScore: 75,
        overallScore: 78,
      );

      expect(video.id, isA<String?>());
      expect(analysis.id, isA<String?>());
      expect(analysis.swimVideoId, isA<String?>());
      expect(analysis.swimVideoId, video.id);
    });

    test('only one SwimVideo class exists under lib/', () {
      final matches = _findDeclarationFiles(
        directory: 'lib',
        pattern: RegExp(r'class SwimVideo\b'),
      );
      expect(
        matches,
        ['lib/data/models/swim_video.dart'],
        reason: 'Duplicate SwimVideo models cause UUID/int type errors',
      );
    });

    test('only one SwimVideoAnalysis class exists under lib/', () {
      final matches = _findDeclarationFiles(
        directory: 'lib',
        pattern: RegExp(r'class SwimVideoAnalysis\b'),
      );
      expect(
        matches,
        ['lib/data/models/swim_video_analysis.dart'],
        reason: 'Duplicate analysis models cause inconsistent swimVideoId types',
      );
    });

    test('only one analysisForVideo method exists under lib/', () {
      final matches = _findDeclarationFiles(
        directory: 'lib',
        pattern: RegExp(r'\w+\??\s+analysisForVideo\s*\([^)]*\)\s*\{'),
      );
      expect(
        matches,
        ['lib/providers/swimmer_data_provider.dart'],
        reason: 'Duplicate analysisForVideo lookups cause stale analysis state',
      );
    });
  });
}

List<String> _findDeclarationFiles({
  required String directory,
  required RegExp pattern,
}) {
  final matches = <String>[];
  final root = Directory(directory);
  if (!root.existsSync()) return matches;

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('video_models.dart')) continue;
    final content = entity.readAsStringSync();
    if (pattern.hasMatch(content)) {
      matches.add(entity.path.replaceAll('\\', '/'));
    }
  }
  matches.sort();
  return matches;
}
