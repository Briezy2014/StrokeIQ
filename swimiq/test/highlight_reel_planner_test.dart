import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/recruiting/highlight_reel_planner.dart';
import 'package:swimiq/data/models/swim_video.dart';
import 'package:swimiq/data/models/video_engine_v2/analysis_results.dart';

void main() {
  test('planner orders tags for recruiting story and keeps storage paths', () {
    final videos = [
      const SwimVideo(
        id: 'vid-1',
        swimmer: 'Aspyn',
        storagePath: 'user/fly2.mp4',
        title: 'Fly 2',
        stroke: 'Butterfly',
        distance: '50',
        course: 'LCM',
      ),
      const SwimVideo(
        id: 'vid-2',
        swimmer: 'Aspyn',
        storagePath: 'user/denison.mp4',
        title: 'Denison 50 Fly',
        stroke: 'Butterfly',
        distance: '50',
        course: 'LCM',
      ),
    ];

    final segments = HighlightReelPlanner.buildSegments(
      tagsByVideoId: {
        'vid-2': {'Sprint finish'},
        'vid-1': {'Best start', 'Race'},
      },
      videos: videos,
      analysisByVideoId: {
        'vid-1': const AnalysisResults(
          jobId: 'job-1',
          status: 'completed',
          engineVersion: 'test',
          phases: [
            AnalysisPhase(
              name: 'underwater_phase',
              startMs: 0,
              endMs: 1800,
            ),
          ],
          video: {'duration_ms': 12000},
        ),
      },
    );

    expect(segments.map((s) => s.tag).toList(), [
      'Best start',
      'Sprint finish',
      'Race',
    ]);
    expect(segments.first.startMs, 0);
    expect(segments.first.endMs, 1800);
    expect(segments.every((s) => s.storagePath.isNotEmpty), isTrue);
  });

  test('planner skips videos without storage path', () {
    final segments = HighlightReelPlanner.buildSegments(
      tagsByVideoId: {
        'vid-1': {'Best start'},
      },
      videos: const [
        SwimVideo(
          id: 'vid-1',
          swimmer: 'Aspyn',
          storagePath: '',
          title: 'Missing path',
        ),
      ],
    );
    expect(segments, isEmpty);
  });
}
