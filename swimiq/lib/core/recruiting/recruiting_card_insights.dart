/// Compact recruiting insights for the wallet-sized SwimIQ card.
class RecruitingCardInsights {
  const RecruitingCardInsights({
    required this.achievementBadge,
    required this.highlight,
  });

  /// One major achievement badge (e.g. Sectional Qualifier).
  final String achievementBadge;

  /// One short recruiting highlight a coach can scan in seconds.
  final String highlight;

  static RecruitingCardInsights from({
    required String highestCut,
    required List<String> topEvents,
    required int swimIqScore,
    String? primaryStrokeHint,
  }) {
    final badge = _badgeFromCut(highestCut);
    final highlight = _highlightFrom(
      highestCut: highestCut,
      topEvents: topEvents,
      swimIqScore: swimIqScore,
      primaryStrokeHint: primaryStrokeHint,
    );
    return RecruitingCardInsights(
      achievementBadge: badge,
      highlight: highlight,
    );
  }

  static String _badgeFromCut(String highestCut) {
    final cut = highestCut.trim();
    if (cut.isEmpty || cut.toLowerCase().contains('log')) {
      return 'Rising Athlete';
    }
    final upper = cut.toUpperCase();
    if (upper.contains('AAAA') || upper.contains('NATIONAL')) {
      return 'National Contender';
    }
    if (upper.contains('AAA') || upper.contains('SECTION')) {
      return 'Sectional Qualifier';
    }
    if (upper.contains('AA') || upper.contains('ZONE')) {
      return 'Zone / AA Qualifier';
    }
    if (upper.contains('A ') ||
        upper.endsWith(' A') ||
        upper == 'A' ||
        upper.contains('JO') ||
        upper.contains('JUNIOR')) {
      return 'JO Qualifier';
    }
    if (upper.contains('BB') || upper.contains('STATE')) {
      return 'State Qualifier';
    }
    return '$cut Standard';
  }

  static String _highlightFrom({
    required String highestCut,
    required List<String> topEvents,
    required int swimIqScore,
    String? primaryStrokeHint,
  }) {
    final cut = highestCut.trim();
    final stroke = _inferStroke(topEvents, primaryStrokeHint);

    if (cut.isNotEmpty &&
        !cut.toLowerCase().contains('log') &&
        stroke != null) {
      return '$cut $stroke Specialist.';
    }
    if (cut.isNotEmpty && !cut.toLowerCase().contains('log')) {
      return 'Earned $cut Motivational Standard.';
    }
    if (stroke != null && topEvents.isNotEmpty) {
      return '$stroke-focused racing portfolio.';
    }
    if (swimIqScore >= 80) {
      return 'High SwimIQ Score — championship-ready profile.';
    }
    if (swimIqScore >= 60) {
      return 'Consistent competitor building toward cuts.';
    }
    if (topEvents.isNotEmpty) {
      return 'Personal bests logged — ready for recruiting review.';
    }
    return 'Complete passport details to unlock recruiting highlights.';
  }

  static String? _inferStroke(List<String> topEvents, String? hint) {
    final blob = '${topEvents.join(' ')} ${hint ?? ''}'.toLowerCase();
    if (blob.contains('butterfly') || blob.contains(' fly')) return 'Butterfly';
    if (blob.contains('backstroke') || blob.contains('back')) return 'Backstroke';
    if (blob.contains('breaststroke') || blob.contains('breast')) {
      return 'Breaststroke';
    }
    if (blob.contains('freestyle') || blob.contains('free')) return 'Freestyle';
    if (blob.contains('im')) return 'IM';
    return null;
  }
}
