import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/youth_friendly_analysis.dart';
import 'package:swimiq/data/models/swim_video_analysis.dart';

void main() {
  test('sanitize removes blocked language', () {
    expect(
      YouthFriendlyAnalysis.sanitize('Great kick tempo — keep it up.'),
      'Great kick tempo — keep it up.',
    );
    expect(
      YouthFriendlyAnalysis.sanitize('That was stupid technique on the turn.'),
      'That was technique on the turn.',
    );
  });

  test('sanitizeAnalysis cleans stored sections', () {
    final cleaned = YouthFriendlyAnalysis.sanitizeAnalysis(
      SwimVideoAnalysis(
        swimmer: 'Aspyn',
        summary: '50 Fly\nSupportive summary',
        strengths: 'Quick pro\n• Strong breakout',
        improvements: 'Top 3\n• Head position',
        techniqueScore: 80,
        paceScore: 78,
        overallScore: 79,
        analysisJson: {
          'sections': {
            'Quick Summary': 'Supportive summary',
            'Quick pro from this video': 'Strong breakout',
          },
          'top_3_priorities': ['Head position', 'Kick tempo'],
        },
      ),
    );

    expect(cleaned.summary, contains('Supportive summary'));
    expect(cleaned.analysisJson?['youth_friendly'], isTrue);
  });
}
