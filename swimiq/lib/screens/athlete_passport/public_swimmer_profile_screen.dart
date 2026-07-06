import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/recruiting_passport_service.dart';
import '../../core/utils/passport_metrics.dart';
import '../../core/utils/swim_time.dart';
import '../../core/utils/swimiq_standards_profile.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/passport_social_links.dart';
import '../../widgets/swimiq_logo.dart';
import '../../widgets/swimiq_ui.dart';
import 'beyond_the_pool_tab.dart';

/// Read-only passport for peers and recruiters (public profiles only).
class PublicSwimmerProfileScreen extends ConsumerWidget {
  const PublicSwimmerProfileScreen({
    super.key,
    required this.profile,
  });

  final SwimmerProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!profile.publicPassportEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Swimmer passport')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'This athlete has not shared their passport publicly.',
          ),
        ),
      );
    }

    final snapshotAsync = ref.watch(
      publicPassportSnapshotProvider(profile.swimmerName),
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(profile.displayName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Passport'),
              Tab(text: 'Beyond the Pool'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            snapshotAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PublicHero(profile: profile),
                  const SizedBox(height: 16),
                  Text('Could not load full stats: $error'),
                  const SizedBox(height: 16),
                  _IdentityCard(profile: profile),
                ],
              ),
              data: (bundle) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PublicHero(profile: profile),
                  const SizedBox(height: 16),
                  if (!SwimIqStandardsProfile.isReady(profile)) ...[
                    const SwimIqStandardsSetupBanner(),
                    const SizedBox(height: 12),
                  ],
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      SwimIqMetricCard(
                        label: 'SwimIQ Score™',
                        value: bundle.snapshot.swimIqScore > 0
                            ? '${bundle.snapshot.swimIqScore}'
                            : '—',
                      ),
                      SwimIqMetricCard(
                        label: 'Highest Cut',
                        value: bundle.snapshot.highestCut,
                      ),
                      SwimIqMetricCard(
                        label: 'Current Focus',
                        value: bundle.snapshot.currentFocus,
                      ),
                      SwimIqMetricCard(
                        label: 'Readiness',
                        value: bundle.snapshot.readiness,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _IdentityCard(profile: profile),
                  const SizedBox(height: 12),
                  SwimIqSectionCard(
                    title: 'Personal bests',
                    lines: bundle.personalBestLines.isEmpty
                        ? const ['No times logged yet.']
                        : bundle.personalBestLines,
                  ),
                  const SizedBox(height: 12),
                  SwimIqSectionCard(
                    title: 'Recruiting snapshot',
                    lines: RecruitingPassportService.build(
                      data: bundle.data,
                      swimmer: profile.swimmerName,
                    ).highlights,
                  ),
                ],
              ),
            ),
            BeyondThePoolTab(
              swimmer: profile.swimmerName,
              profile: profile,
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }
}

class PublicPassportBundle {
  const PublicPassportBundle({
    required this.data,
    required this.snapshot,
    required this.personalBestLines,
  });

  final SwimmerData data;
  final PassportSnapshot snapshot;
  final List<String> personalBestLines;
}

final publicPassportSnapshotProvider =
    FutureProvider.family<PublicPassportBundle, String>((ref, swimmer) async {
  final repository = ref.read(swimIqRepositoryProvider);
  final profile = await repository.fetchProfile(swimmer);
  if (profile == null || !profile.publicPassportEnabled) {
    throw Exception('Profile is not public.');
  }

  final raceLogs = await repository.fetchRaceLogs(swimmer);
  final goals = await repository.fetchGoals(swimmer);
  final meetResults = await repository.fetchMeetResults(swimmer);
  final motivationalStandards =
      await ref.read(usaMotivationalStandardsCatalogProvider.future);

  final data = SwimmerData(
    raceLogs: raceLogs,
    goals: goals,
    meetResults: meetResults,
    profile: profile,
    motivationalStandards: motivationalStandards,
  );

  final snapshot = data.passportSnapshot(swimmer);
  final pbLines = data.personalBests
      .take(8)
      .map(
        (pb) =>
            '${pb.distance} ${pb.stroke} ${pb.course} — ${SwimTime.fromSeconds(pb.timeSeconds)}',
      )
      .toList();

  return PublicPassportBundle(
    data: data,
    snapshot: snapshot,
    personalBestLines: pbLines,
  );
});

class _PublicHero extends StatelessWidget {
  const _PublicHero({required this.profile});

  final SwimmerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white,
            backgroundImage: profile.profilePhotoUrl != null &&
                    profile.profilePhotoUrl!.isNotEmpty
                ? NetworkImage(profile.profilePhotoUrl!)
                : null,
            child: profile.profilePhotoUrl == null ||
                    profile.profilePhotoUrl!.isEmpty
                ? const SwimIqLogo(size: 72, borderRadius: 36)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            profile.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          if (profile.team != null && profile.team!.isNotEmpty)
            Text(
              profile.team!,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white70),
            ),
          PassportSocialLinks(
            profile: profile,
            iconColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final SwimmerProfile profile;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    return SwimIqSectionCard(
      title: 'Athlete identity',
      lines: [
        if (profile.school != null && profile.school!.isNotEmpty)
          'School: ${profile.school}',
        if (profile.graduationYear != null)
          'Class of ${profile.graduationYear}',
        if (profile.primaryStroke != null && profile.primaryStroke!.isNotEmpty)
          'Primary stroke: ${profile.primaryStroke}',
        if (profile.favoriteEvent != null && profile.favoriteEvent!.isNotEmpty)
          'Focus event: ${profile.favoriteEvent}',
        if (profile.coachName != null && profile.coachName!.isNotEmpty)
          'Coach: ${profile.coachName}',
        if (profile.birthday != null)
          'Birthday: ${dateFormat.format(profile.birthday!)}',
      ],
    );
  }
}
