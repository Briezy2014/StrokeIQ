import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/services/passport_ai_recommendation.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../providers/app_providers.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swim_iq_feature_scaffold.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/video_analysis_report.dart';

class AiCoachScreen extends ConsumerWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwimIqFeatureScaffold(
      title: 'AI Coach',
      body: SubscriptionGatedScreen(
        minimumTier: SubscriptionTier.elite,
        title: 'Unlock SwimIQ Elite',
        message:
            'AI Coach feedback is included with Elite — stroke analysis, top 3 '
            'practice priorities, and parent-friendly performance reports.',
        teaserFeatures: const [
          'AI Stroke Analysis — mechanics, kick, turns & more',
          'Top 3 practice priorities from your race videos',
          'Race Intelligence — pacing, splits & fatigue detection',
          'AI Performance Reports & race strategy',
        ],
        child: SwimmerScreen(
          builder: (context, ref, data, swimmer) {
            final recommendation = PassportAiRecommendation.build(
              data: data,
              swimmer: swimmer,
            );
            final analyses = data.userFacingVideoAnalyses;
            final latest = _latestAnalysis(analyses);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const SwimIqPageHero(
                  title: 'AI Coach',
                  subtitle:
                      'Your coaching feedback — priorities, strengths, and what to train next.',
                ),
                const SizedBox(height: 12),
                _CoachSummaryCard(recommendation: recommendation),
                if (recommendation.priorities.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PriorityList(priorities: recommendation.priorities),
                ],
                if (latest != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Latest AI Coach report',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                  ),
                  const SizedBox(height: 8),
                  VideoAnalysisReport(
                    analysis: latest,
                    onCoachNotesChanged: (_) {},
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'No AI Coach report yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recommendation.detail,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.45,
                                ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () {
                              ref.read(homeTabIndexProvider.notifier).state =
                                  HomeTab.videoLab;
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            icon: const Icon(Icons.videocam_outlined),
                            label: const Text('Upload video in Video Lab'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  recommendation.engineLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static SwimVideoAnalysis? _latestAnalysis(List<SwimVideoAnalysis> analyses) {
    if (analyses.isEmpty) return null;
    final sorted = [...analyses]
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return sorted.first;
  }
}

class _CoachSummaryCard extends StatelessWidget {
  const _CoachSummaryCard({required this.recommendation});

  final PassportAiRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recommendation.headline,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
            ),
            if (recommendation.suggestedEvent != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  recommendation.suggestedEvent!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              recommendation.detail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityList extends StatelessWidget {
  const _PriorityList({required this.priorities});

  final List<String> priorities;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top practice priorities',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            ...priorities.take(3).map(
                  (priority) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('→ '),
                        Expanded(
                          child: Text(
                            priority,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
