import '../../providers/swimmer_data_provider.dart';

class SwimDnaTrait {
  const SwimDnaTrait({
    required this.label,
    required this.value,
    required this.insight,
  });

  final String label;
  final String value;
  final String insight;
}

class SwimDnaProfile {
  const SwimDnaProfile({
    required this.headline,
    required this.subtitle,
    required this.traits,
    required this.strengths,
    required this.growthEdges,
    required this.engineLabel,
  });

  final String headline;
  final String subtitle;
  final List<SwimDnaTrait> traits;
  final List<String> strengths;
  final List<String> growthEdges;
  final String engineLabel;
}

/// Athlete swimming identity — strokes, readiness, cuts, and training DNA.
class SwimDnaService {
  SwimDnaService._();

  static const engineLabel =
      'SwimDNA™ · built from your passport, times, goals, and video coaching data';

  static SwimDnaProfile build({
    required SwimmerData data,
    required String swimmer,
  }) {
    final snapshot = data.passportSnapshot(swimmer);
    final profile = data.profile;
    final displayName = snapshot.displayName;

    final primaryStroke = _label(profile?.primaryStroke, 'Multi-stroke');
    final secondaryStroke = _label(profile?.secondaryStroke, 'Still exploring');
    final favoriteEvent = _label(profile?.favoriteEvent, snapshot.currentFocus);

    final traits = <SwimDnaTrait>[
      SwimDnaTrait(
        label: 'Primary stroke',
        value: primaryStroke,
        insight: 'Your passport anchors training around $primaryStroke.',
      ),
      SwimDnaTrait(
        label: 'Secondary stroke',
        value: secondaryStroke,
        insight: secondaryStroke == 'Still exploring'
            ? 'Add a secondary stroke to unlock crossover insights.'
            : '$secondaryStroke adds range to your race portfolio.',
      ),
      SwimDnaTrait(
        label: 'Signature event',
        value: favoriteEvent,
        insight: 'Race Intelligence and AI Coach prioritize $favoriteEvent.',
      ),
      SwimDnaTrait(
        label: 'SwimIQ score',
        value: '${snapshot.swimIqScore}',
        insight: snapshot.swimIqExplanation,
      ),
      SwimDnaTrait(
        label: 'Readiness',
        value: snapshot.readiness,
        insight: 'Updated from sessions, goals, and coaching activity.',
      ),
      SwimDnaTrait(
        label: 'Highest cut',
        value: snapshot.highestCut,
        insight: 'USA motivational standards from official meet times.',
      ),
      SwimDnaTrait(
        label: 'IMX / IMR',
        value: snapshot.imxScore,
        insight: 'Versatility score from logged training events.',
      ),
      SwimDnaTrait(
        label: 'Video coaching',
        value: snapshot.analysisCount > 0
            ? '${snapshot.analysisCount} AI reports'
            : snapshot.videoCount > 0
                ? '${snapshot.videoCount} uploads · run analysis'
                : 'No videos yet',
        insight: snapshot.analysisCount > 0
            ? 'SwimDNA learns from your latest AI Coach priorities.'
            : 'Upload race video in Video Lab to sharpen SwimDNA.',
      ),
    ];

    final strengths = <String>[
      if (snapshot.personalBests.isNotEmpty)
        'Fastest times: ${snapshot.personalBests.take(3).join(' · ')}',
      if (snapshot.goalLines.isNotEmpty)
        'Goal tracking: ${snapshot.goalLines.first}',
      if (snapshot.readiness == 'Race Ready' || snapshot.readiness == 'Coaching Active')
        'Competition-ready profile with active coaching signals.',
      if (profile?.gpa?.trim().isNotEmpty == true)
        'Academic profile on file for recruiting conversations.',
    ];

    if (strengths.isEmpty) {
      strengths.add('Passport started — log sessions and goals to build your DNA.');
    }

    final growthEdges = <String>[
      snapshot.nextFocus,
      if (snapshot.videoCount == 0)
        'Add a race video and run Elite analysis so AI Coach can rank practice priorities.',
      if (snapshot.analysisCount == 0 && snapshot.videoCount > 0)
        'Run AI analysis on your latest upload to unlock coaching DNA.',
      if (data.goals.isEmpty) 'Set a goal event to sharpen training focus.',
    ];

    return SwimDnaProfile(
      headline: '$displayName\'s SwimDNA™',
      subtitle:
          'Your swimming identity — strokes, readiness, cuts, and what to train next.',
      traits: traits,
      strengths: strengths,
      growthEdges: growthEdges,
      engineLabel: engineLabel,
    );
  }

  static String _label(String? value, String fallback) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed;
  }
}
