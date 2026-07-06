import '../../providers/swimmer_data_provider.dart';

class WellnessReadinessBrief {
  const WellnessReadinessBrief({
    required this.headline,
    required this.readinessLabel,
    required this.readinessScore,
    required this.summary,
    required this.factors,
    required this.recommendations,
    required this.sleepHours,
    required this.sorenessLevel,
    required this.illnessNotes,
  });

  final String headline;
  final String readinessLabel;
  final int readinessScore;
  final String summary;
  final List<String> factors;
  final List<String> recommendations;
  final String? sleepHours;
  final String? sorenessLevel;
  final String? illnessNotes;
}

/// Wellness & readiness score from passport check-in fields + training load.
abstract final class WellnessReadinessService {
  static WellnessReadinessBrief build({
    required SwimmerData data,
    required String swimmer,
  }) {
    final profile = data.profile;
    final sleep = profile?.sleepHours;
    final soreness = profile?.sorenessLevel;
    final illness = profile?.illnessNotes;
    final recentSessions = data.raceLogs.length;
    final hasGoals = data.goals.isNotEmpty;

    var score = 70;
    final factors = <String>[];
    final recommendations = <String>[];

    final sleepValue = _parseSleep(sleep);
    if (sleepValue != null) {
      if (sleepValue >= 8) {
        score += 10;
        factors.add('Sleep: ${sleepValue.toStringAsFixed(1)}h — good recovery');
      } else if (sleepValue >= 6) {
        factors.add('Sleep: ${sleepValue.toStringAsFixed(1)}h — moderate');
        recommendations.add('Aim for 8+ hours before hard race-pace sets.');
      } else {
        score -= 15;
        factors.add('Sleep: ${sleepValue.toStringAsFixed(1)}h — low');
        recommendations.add('Prioritize sleep tonight — biggest recovery lever.');
      }
    } else {
      factors.add('Sleep not logged — add hours in Passport wellness check-in.');
      recommendations.add('Log last night\'s sleep in Athlete Passport.');
    }

    final sorenessScore = _sorenessImpact(soreness);
    score += sorenessScore.delta;
    if (soreness != null && soreness.trim().isNotEmpty) {
      factors.add('Soreness: $soreness — ${sorenessScore.label}');
      if (sorenessScore.delta < 0) {
        recommendations.add('Consider extra warm-up and mobility before main set.');
      }
    }

    if (illness != null && illness.trim().isNotEmpty) {
      score -= 20;
      factors.add('Illness / injury note: $illness');
      recommendations.add('Communicate with coach — adjust volume if not 100%.');
    }

    if (recentSessions >= 4) {
      score -= 5;
      factors.add('$recentSessions sessions logged — watch cumulative fatigue.');
    } else if (recentSessions == 0) {
      score -= 10;
      factors.add('No recent sessions — readiness unknown.');
    }

    if (hasGoals) {
      score += 5;
      factors.add('Active goals — training intent is clear.');
    }

    score = score.clamp(0, 100);
    final label = _labelForScore(score);

    return WellnessReadinessBrief(
      headline: 'Wellness & readiness',
      readinessLabel: label,
      readinessScore: score,
      summary:
          'Daily check-in from Passport (sleep, soreness, illness) combined '
          'with your training log — not medical advice.',
      factors: factors,
      recommendations: recommendations.isEmpty
          ? const ['Keep logging wellness check-ins before big training days.']
          : recommendations,
      sleepHours: sleep,
      sorenessLevel: soreness,
      illnessNotes: illness,
    );
  }

  static double? _parseSleep(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return double.tryParse(raw.trim().replaceAll(RegExp(r'[^0-9.]'), ''));
  }

  static ({int delta, String label}) _sorenessImpact(String? soreness) {
    if (soreness == null || soreness.trim().isEmpty) {
      return (delta: 0, label: 'not logged');
    }
    final lower = soreness.toLowerCase();
    if (lower.contains('none') || lower.contains('fresh')) {
      return (delta: 10, label: 'fresh');
    }
    if (lower.contains('mild') || lower.contains('low')) {
      return (delta: 0, label: 'manageable');
    }
    if (lower.contains('moderate')) {
      return (delta: -10, label: 'elevated');
    }
    if (lower.contains('high') || lower.contains('severe')) {
      return (delta: -20, label: 'high');
    }
    return (delta: -5, label: 'noted');
  }

  static String _labelForScore(int score) {
    if (score >= 85) return 'Green — go for quality work';
    if (score >= 65) return 'Yellow — train smart';
    if (score >= 45) return 'Orange — reduce intensity';
    return 'Red — recovery priority';
  }
}
