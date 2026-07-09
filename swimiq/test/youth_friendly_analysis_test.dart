import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/youth_coaching_phrases.dart';
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

  test('plainLanguage explains swim jargon for younger swimmers', () {
    expect(
      YouthFriendlyAnalysis.plainLanguage(
        'Drive full extension on the last stroke at the wall.',
      ),
      YouthCoachingPhrases.finishFocusPriority,
    );
    expect(
      YouthFriendlyAnalysis.plainLanguage(
        'Strong finish — you drove full extension into the wall.',
      ),
      contains('complete last stroke'),
    );
    expect(
      YouthFriendlyAnalysis.plainLanguage('Hold streamline longer before breakout.'),
      YouthCoachingPhrases.holdStreamlinePriority,
    );
    expect(
      YouthFriendlyAnalysis.plainLanguage('Solid breakout at 11m'),
      contains('coming up for your first stroke after underwater'),
    );
  });

  test('sanitize keeps precise body mechanics technique terms', () {
    expect(
      YouthFriendlyAnalysis.sanitize(
        'Hips are dropping — keep hips up and head down in streamline.',
      ),
      contains('hips up'),
    );
    expect(
      YouthFriendlyAnalysis.sanitize(
        'Hips are dropping — keep hips up and head down in streamline.',
      ),
      contains('underwater arrow position'),
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
            'Top 3 priorities for your next race':
                '• Drive full extension on the last stroke at the wall.',
          },
          'top_3_priorities': [
            'Drive full extension on the last stroke at the wall.',
            'Head position',
          ],
        },
      ),
    );

    expect(cleaned.summary, contains('Supportive summary'));
    expect(cleaned.analysisJson?['youth_friendly'], isTrue);
    expect(
      cleaned.analysisJson?['top_3_priorities']?.first,
      YouthCoachingPhrases.finishFocusPriority,
    );
    final sections = cleaned.analysisJson?['sections'] as Map<String, dynamic>?;
    expect(
      sections?['Top 3 priorities for your next race'],
      contains('final stroke completely'),
    );
  });
}
