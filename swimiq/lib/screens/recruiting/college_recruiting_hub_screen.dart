import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swim_iq_feature_scaffold.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_page_hero.dart';
import 'highlight_video_builder_screen.dart';
import 'meet_history_screen.dart';
import 'recruiting_resume_screen.dart';
import 'recruiting_intelligence_screen.dart';

/// Pro-tier recruiting command center.
class CollegeRecruitingHubScreen extends ConsumerWidget {
  const CollegeRecruitingHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwimIqFeatureScaffold(
      title: 'Recruiting Center',
      body: SubscriptionGatedScreen(
      minimumTier: SubscriptionTier.pro,
      title: 'Unlock SwimIQ Pro',
      message: 'The College Recruiting Hub is included with Pro — athlete passport, '
          'résumé builder, meet history, and highlight video organization.',
      teaserFeatures: const [
        'College Recruiting Hub & Athlete Passport',
        'Best Times Résumé — export for coaches',
        'Meet History & lifetime progression',
        'Highlight Video Builder',
      ],
      child: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
          final profile = data.profile;
          final snapshot = data.passportSnapshot(swimmer);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const SwimIqPageHero(
                title: 'College Recruiting Hub',
                subtitle: 'Prepare your recruiting package — passport, résumé, '
                    'meet history & videos in one place.',
              ),
              const SizedBox(height: 16),
              _ProfileSummaryCard(
                displayName: profile?.displayName ?? swimmer,
                graduationYear: profile?.graduationYear,
                recruitingStatus: profile?.recruitingStatus,
                club: profile?.team,
                school: profile?.school,
                coach: profile?.coachName,
                coachContact: profile?.coachEmail ?? profile?.recruitingEmail,
                gpa: profile?.gpa,
                sat: profile?.satScore,
                act: profile?.actScore,
                major: profile?.intendedMajor,
                usaId: profile?.usaSwimmingId,
              ),
              const SizedBox(height: 16),
              _HubTile(
                emoji: '📄',
                title: 'Best Times Résumé',
                subtitle: 'One-page recruiting résumé with top times, honors & academics',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RecruitingResumeScreen(),
                  ),
                ),
              ),
              _HubTile(
                emoji: '📅',
                title: 'Meet History',
                subtitle: 'Attendance, seasonal improvement & championship swims',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MeetHistoryScreen(),
                  ),
                ),
              ),
              _HubTile(
                emoji: '🎥',
                title: 'Highlight Video Builder',
                subtitle: 'Tag races, starts, turns & finishes for recruiting reels',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HighlightVideoBuilderScreen(),
                  ),
                ),
              ),
              _HubTile(
                emoji: '🤖',
                title: 'AI Recruiting Intelligence',
                subtitle: 'College Match, time projections & event recommendations',
                badge: 'Elite',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RecruitingIntelligenceScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick snapshot',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text('SwimIQ ${snapshot.swimIqScore} · ${snapshot.highestCut}'),
                      Text('${data.personalBests.length} official PBs · '
                          '${data.meetResults.length} meet swims'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.displayName,
    this.graduationYear,
    this.recruitingStatus,
    this.club,
    this.school,
    this.coach,
    this.coachContact,
    this.gpa,
    this.sat,
    this.act,
    this.major,
    this.usaId,
  });

  final String displayName;
  final int? graduationYear;
  final String? recruitingStatus;
  final String? club;
  final String? school;
  final String? coach;
  final String? coachContact;
  final String? gpa;
  final String? sat;
  final String? act;
  final String? major;
  final String? usaId;

  @override
  Widget build(BuildContext context) {
    String line(String label, String? value) {
      final text = value?.trim();
      if (text == null || text.isEmpty) return '$label: —';
      return '$label: $text';
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
            ),
            const SizedBox(height: 8),
            Text(line('Class of', graduationYear?.toString())),
            Text(line('Recruiting status', recruitingStatus)),
            Text(line('Club', club)),
            Text(line('High school', school)),
            Text(line('Coach', coach)),
            Text(line('Coach contact', coachContact)),
            Text(line('GPA', gpa)),
            Text(line('SAT / ACT', sat != null || act != null
                ? '${sat ?? '—'} / ${act ?? '—'}'
                : null)),
            Text(line('Intended major', major)),
            Text(line('USA Swimming ID', usaId)),
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
