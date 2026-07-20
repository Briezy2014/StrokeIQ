import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/recruiting/recruiting_intelligence_engine.dart';
import '../../core/services/college_recruiting_benchmark_catalog.dart';
import '../../core/services/gemini_college_match_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/swim_time.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_page_hero.dart';

/// Elite-tier AI recruiting intelligence with benchmark-matched schools.
class RecruitingIntelligenceScreen extends ConsumerStatefulWidget {
  const RecruitingIntelligenceScreen({super.key});

  @override
  ConsumerState<RecruitingIntelligenceScreen> createState() =>
      _RecruitingIntelligenceScreenState();
}

class _RecruitingIntelligenceScreenState
    extends ConsumerState<RecruitingIntelligenceScreen> {
  RecruitingIntelligenceReport? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  Future<void> _loadReport() async {
    final data = ref.read(swimmerDataProvider).value;
    if (data == null || !mounted) {
      setState(() => _loading = false);
      return;
    }

    final profile = data.profile;
    final passportComplete = profile != null &&
        (profile.graduationYear != null ||
            profile.team != null ||
            profile.gpa != null);

    try {
      final catalog = await CollegeRecruitingBenchmarkCatalog.loadFromAssets();
      final matches = catalog.matchSchools(
        personalBests: data.personalBests,
        profile: profile,
      );

      String? geminiSummary;
      if (matches.isNotEmpty) {
        try {
          geminiSummary = await ref
              .read(geminiCollegeMatchServiceProvider)
              .summarizeMatches(
                profile: profile,
                personalBests: data.personalBests,
                matches: matches,
                benchmarkDisclaimer: catalog.disclaimer,
              );
        } catch (_) {
          geminiSummary = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _report = RecruitingIntelligenceEngine.build(
          profile: profile,
          personalBests: data.personalBests,
          swimIqScore: data.swimIqScore,
          meetCount: data.meetResults.map((m) => m.meetName).toSet().length,
          videoCount: data.userFacingVideos.length,
          passportComplete: passportComplete,
          benchmarkCatalog: catalog,
          geminiCoachSummary: geminiSummary,
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _report = RecruitingIntelligenceEngine.build(
          profile: profile,
          personalBests: data.personalBests,
          swimIqScore: data.swimIqScore,
          meetCount: data.meetResults.map((m) => m.meetName).toSet().length,
          videoCount: data.userFacingVideos.length,
          passportComplete: passportComplete,
        );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubscriptionGatedScreen(
      minimumTier: SubscriptionTier.elite,
      title: 'Unlock SwimIQ Elite',
      message: 'AI Recruiting Intelligence is included with Elite — college match '
          'projections, time forecasts, event recommendations & improvement curves.',
      teaserFeatures: const [
        'College Match AI — reach, target & likely schools',
        'Time Projection AI — gap to school targets',
        'Event Recommendation AI — maximize recruiting potential',
        'AI Recruiting Assistant & improvement curve',
      ],
      child: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final report = _report;
          if (report == null) {
            return const Center(child: Text('Load swimmer data to see recruiting AI.'));
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const SwimIqPageHero(
                title: 'AI Recruiting Intelligence',
                subtitle: 'Named schools matched to your official times — verify '
                    'every list with coaches before contacting programs.',
              ),
              const SizedBox(height: 16),
              _AssistantCard(report: report),
              if (report.geminiCoachSummary != null) ...[
                const SizedBox(height: 12),
                _GeminiSummaryCard(summary: report.geminiCoachSummary!),
              ],
              const SizedBox(height: 12),
              _IntelSection(
                emoji: '🎯',
                title: 'College Match AI',
                lines: [
                  'Based on your times and improvement rate, you are currently '
                  'competitive for:',
                  ...report.divisionFit.map((d) => '• $d'),
                  '',
                  'Division overview — reach / target / likely (projections):',
                  'Reach schools:',
                  ...report.genericReachSchools,
                  'Target schools:',
                  ...report.genericTargetSchools,
                  'Likely schools:',
                  ...report.genericLikelySchools,
                  if (report.usedNamedSchoolMatching) ...[
                    '',
                    'Named schools matched to your official times (Ohio & Midwest benchmarks):',
                    'Reach schools (need faster times):',
                    ...report.reachSchools,
                    'Target schools (close to recruit range):',
                    ...report.targetSchools,
                    'Likely schools (times already in range):',
                    ...report.likelySchools,
                  ],
                ],
              ),
              _IntelSection(
                emoji: '📈',
                title: 'Time Projection AI',
                lines: report.timeProjections.isEmpty
                    ? ['Log official times to unlock projections.']
                    : report.timeProjections
                        .map(
                          (p) =>
                              'Current ${p.eventLabel}: ${p.currentTime}\n'
                              'AI projection next championship season: ${p.projectedTime}\n'
                              'Needed for ${p.targetSchoolName ?? 'target school'}: ${p.targetSchoolTime}\n'
                              'Gap: ${SwimTime.fromSeconds(p.gapSeconds)}',
                        )
                        .toList(),
              ),
              _IntelSection(
                emoji: '🏊',
                title: 'Event Recommendation AI',
                lines: report.eventRecommendations,
              ),
              _IntelSection(
                emoji: '📊',
                title: 'Improvement Curve',
                lines: report.improvementCurve,
              ),
              const SizedBox(height: 8),
              Text(
                report.benchmarkDisclaimer.isNotEmpty
                    ? report.benchmarkDisclaimer
                    : 'Elite AI refines projections with more meet data, video analysis, '
                        'and regional recruiting benchmarks.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              if (report.usedNamedSchoolMatching && report.geminiCoachSummary == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'AI coach summary is temporarily unavailable — school matches '
                    'still use SwimIQ benchmarks. Try again later.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GeminiSummaryCard extends StatelessWidget {
  const _GeminiSummaryCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gemini recruiting read',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
            ),
            const SizedBox(height: 8),
            Text(summary, style: const TextStyle(height: 1.45)),
          ],
        ),
      ),
    );
  }
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard({required this.report});

  final RecruitingIntelligenceReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDeep.withValues(alpha: 0.95),
              AppColors.primary,
            ],
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🧬', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'Recruiting Status',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              report.recruitingLevel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 14),
            _AssistantBlock(
              title: 'Strengths',
              items: report.strengths,
              light: true,
            ),
            const SizedBox(height: 10),
            _AssistantBlock(
              title: 'Focus areas',
              items: report.focusAreas,
              light: true,
            ),
            const SizedBox(height: 10),
            _AssistantBlock(
              title: 'Recommended next milestones',
              items: report.milestones,
              light: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantBlock extends StatelessWidget {
  const _AssistantBlock({
    required this.title,
    required this.items,
    this.light = false,
  });

  final String title;
  final List<String> items;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : AppColors.textDark;
    final subColor = light ? Colors.white70 : Colors.grey.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: subColor,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('• $item', style: TextStyle(color: color, height: 1.35)),
          ),
      ],
    );
  }
}

class _IntelSection extends StatelessWidget {
  const _IntelSection({
    required this.emoji,
    required this.title,
    required this.lines,
  });

  final String emoji;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final line in lines)
                if (line.isEmpty)
                  const SizedBox(height: 6)
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line, style: const TextStyle(height: 1.4)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
