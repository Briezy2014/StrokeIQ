import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/swimiq_quotes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/motivational_cut.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../../widgets/swimmer_screen.dart';

class PersonalBestsScreen extends ConsumerWidget {
  const PersonalBestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final personalBests = data.personalBests;
        final dateFormat = DateFormat.yMMMd();
        final quote = SwimIqQuotes.pickFor(swimmer, SwimIqQuotes.personalBests);

        if (personalBests.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              SwimIqPageHero(
                title: 'Personal Bests',
                subtitle: 'Your fastest official meet times',
                quote: quote,
              ),
              const SizedBox(height: 16),
              const EmptyStateMessage(
                message:
                    'No personal bests yet. Add meet results on the Log tab to unlock this page.',
              ),
            ],
          );
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqPageHero(
              title: 'Personal Bests',
              subtitle: '${personalBests.length} events from meet results',
              quote: quote,
              stats: [
                SwimIqHeroStat('${personalBests.length} PBs'),
                SwimIqHeroStat(data.passportSnapshot(swimmer).highestCut),
              ],
            ),
            const SizedBox(height: 16),
            ...personalBests.map(
              (pb) {
                final cut = MotivationalCut.labelForSwim(
                  catalog: data.motivationalStandards,
                  profile: data.profile,
                  stroke: pb.stroke,
                  distance: pb.distance,
                  course: pb.course,
                  timeSeconds: pb.timeSeconds,
                );
                final sourceDetail = pb.meetName ?? pb.eventLabel;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.surfaceLight,
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      pb.displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      '${pb.course} · ${pb.sourceLabel} · ${dateFormat.format(pb.date)}\n'
                      '$sourceDetail · $cut cut',
                    ),
                    isThreeLine: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pb.formattedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
