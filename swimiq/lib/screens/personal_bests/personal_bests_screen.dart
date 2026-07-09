import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/services/usa_motivational_standards_catalog.dart';
import '../../data/models/personal_best_entry.dart';
import '../../data/models/swimmer_profile.dart';
import '../../core/subscription/subscription_capabilities.dart';
import '../../core/utils/motivational_cut.dart';
import '../../core/utils/next_cut_progress.dart';
import '../../core/utils/swimiq_standards_profile.dart';
import '../../widgets/next_cut_progress_strip.dart';
import '../../core/utils/swim_analytics.dart';
import '../../core/utils/swim_time.dart';
import '../../providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/swimiq_event_card.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../../widgets/swimiq_ui.dart';
import '../../widgets/swimmer_screen.dart';
import '../membership/membership_screen.dart';

class PersonalBestsScreen extends ConsumerWidget {
  const PersonalBestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final subscription = ref.watch(subscriptionStateProvider).value;
        final showOfficial = subscription == null ||
            SubscriptionCapabilities.canAccessOfficialPbsAndStandards(
              subscription,
            );

        final officialBests = data.personalBests;
        final trainingBests = SwimAnalytics.personalBests(data.raceLogs);
        final dateFormat = DateFormat.yMMMd();

        if (showOfficial) {
          if (officialBests.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                SwimIqPageHero(
                  showMark: false,
                  title: 'Personal Bests',
                  subtitle: 'Official meet times & USA standards',
                ),
                const SizedBox(height: 16),
                const EmptyStateMessage(
                  message:
                      'No official meet PBs yet. Add meet results on the Meets tab.',
                ),
              ],
            );
          }

          final closestNextCut = _closestNextCut(
            officialBests: officialBests,
            catalog: data.motivationalStandards,
            profile: data.profile,
          );

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              SwimIqPageHero(
                showMark: false,
                title: 'Personal Bests',
                subtitle: '${officialBests.length} official meet PBs',
                stats: [
                  SwimIqHeroStat('${officialBests.length} PBs'),
                  SwimIqHeroStat(data.passportSnapshot(swimmer).highestCut),
                ],
              ),
              if (closestNextCut != null) ...[
                const SizedBox(height: 12),
                NextCutSummaryCard(
                  eventTitle: closestNextCut.title,
                  progress: closestNextCut.progress,
                ),
              ] else if (!SwimIqStandardsProfile.isReady(data.profile)) ...[
                const SizedBox(height: 12),
                const SwimIqStandardsSetupBanner(),
              ],
              const SizedBox(height: 16),
              ...officialBests.map(
                (pb) {
                  final cut = MotivationalCut.labelForSwim(
                    catalog: data.motivationalStandards,
                    profile: data.profile,
                    stroke: pb.stroke,
                    distance: pb.distance,
                    course: pb.course,
                    timeSeconds: pb.timeSeconds,
                  );
                  final nextCut = NextCutAnalytics.forSwim(
                    catalog: data.motivationalStandards,
                    profile: data.profile,
                    stroke: pb.stroke,
                    distance: pb.distance,
                    course: pb.course,
                    timeSeconds: pb.timeSeconds,
                  );
                  final sourceDetail = pb.meetName ?? pb.eventLabel;
                  return SwimIqEventCard(
                    title: pb.displayTitle,
                    subtitle:
                        '${pb.course} · ${pb.sourceLabel} · ${dateFormat.format(pb.date)}\n'
                        '$sourceDetail · $cut cut',
                    trailing: pb.formattedTime,
                    highlight:
                        cut == data.passportSnapshot(swimmer).highestCut,
                    footer: nextCut == null
                        ? null
                        : NextCutProgressStrip(
                            progress: nextCut,
                            compact: true,
                          ),
                  );
                },
              ),
            ],
          );
        }

        // Basic: in-app PB tracking from training log.
        if (trainingBests.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              SwimIqPageHero(
                showMark: false,
                title: 'Personal Bests',
                subtitle: 'In-app tracking from your training log',
              ),
              const SizedBox(height: 16),
              const EmptyStateMessage(
                message:
                    'Log training sessions to track your fastest in-app times. '
                    'Upgrade to Pro for official meet PBs & USA standards.',
              ),
              const SizedBox(height: 16),
              _ProPbsUpsell(),
            ],
          );
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqPageHero(
              showMark: false,
              title: 'Personal Bests',
              subtitle: '${trainingBests.length} in-app bests from training',
              stats: [
                SwimIqHeroStat('${trainingBests.length} events'),
                const SwimIqHeroStat('Training log'),
              ],
            ),
            const SizedBox(height: 16),
            ...trainingBests.map(
              (log) => SwimIqEventCard(
                title: log.event,
                subtitle:
                    '${log.course} · Training log · ${dateFormat.format(log.date)}',
                trailing: SwimTime.fromSeconds(log.timeSeconds),
              ),
            ),
            const SizedBox(height: 20),
            _ProPbsUpsell(),
          ],
        );
      },
    );
  }
}

class _ClosestNextCut {
  const _ClosestNextCut({required this.title, required this.progress});

  final String title;
  final NextCutProgress progress;
}

_ClosestNextCut? _closestNextCut({
  required List<PersonalBestEntry> officialBests,
  required UsaMotivationalStandardsCatalog catalog,
  required SwimmerProfile? profile,
}) {
  _ClosestNextCut? closest;
  for (final pb in officialBests) {
    final progress = NextCutAnalytics.forSwim(
      catalog: catalog,
      profile: profile,
      stroke: pb.stroke,
      distance: pb.distance,
      course: pb.course,
      timeSeconds: pb.timeSeconds,
    );
    if (progress == null || !progress.hasNextCut) continue;
    final gap = progress.gapSeconds;
    if (gap == null || gap <= 0) continue;

    if (closest == null || gap < (closest.progress.gapSeconds ?? double.infinity)) {
      closest = _ClosestNextCut(title: pb.displayTitle, progress: progress);
    }
  }
  return closest;
}

class _ProPbsUpsell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pro = SubscriptionCatalog.planFor(SubscriptionTier.pro);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upgrade for official meet PBs',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SwimIQ Pro adds official meet results, USA Swimming motivational '
              'standards, Athlete Passport, Video Lab, and AI Dryland Coach.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MembershipScreen(),
                  ),
                );
              },
              child: Text('Upgrade to ${pro.name}'),
            ),
          ],
        ),
      ),
    );
  }
}
