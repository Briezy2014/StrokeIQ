import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/video_analysis_presenter.dart';
import 'package:swimiq/data/models/swim_video_analysis.dart';

void main() {
  test('athlete report sections appear in coaching-first order', () {
    const analysis = SwimVideoAnalysis(
      swimmer: 'Aspyn',
      summary: 'test',
      strengths: 'pro',
      improvements: 'con',
      techniqueScore: 80,
      paceScore: 80,
      overallScore: 80,
      analysisJson: {
        'sections': {
          // Intentionally scrambled insertion order (old Gemini dumps).
          'Estimated time savings': '• 0.4–0.6s',
          'Top 3 priorities for your next race': '• Keep hips up',
          'Coach notes for next race': 'Aspyn, eyes down on the breath.',
          'Goal for your next race': 'Flatter hip line',
          'Quick con from this video': 'Hips drop on breath',
          'Quick pro from this video': 'Strong butterfly rhythm',
          'Dryland focus (strength · mobility · stability)': 'Core hold',
        },
      },
    );

    final keys =
        VideoAnalysisPresenter.visibleSections(analysis).keys.toList();
    expect(
      keys,
      [
        'Quick pro from this video',
        'Quick con from this video',
        'Goal for your next race',
        'Coach notes for next race',
        'Estimated time savings',
        'Top 3 priorities for your next race',
        'Dryland focus (strength · mobility · stability)',
      ],
    );
  });
}
