import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/subscription/subscription_capabilities.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/motivational_cut.dart';
import '../../core/utils/swim_time.dart';
import '../../core/services/usa_motivational_standards_catalog.dart';
import '../../data/models/personal_best_entry.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/dashboard_membership_plans_card.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dashboard_cuts_pie_chart.dart';
import '../../widgets/swimiq_rope_climb_card.dart';
import '../../widgets/swimiq_media_picker.dart';
import '../../widgets/swimmer_screen.dart';
import '../../core/gamification/swimiq_badges.dart';
import '../../core/gamification/swimiq_daily_progress.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isUploadingPhoto = false;

  Future<void> _uploadProfilePhoto() async {
    final picked = await pickSwimIqMedia(
      context,
      kind: SwimIqMediaKind.image,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    final error = await ref.read(swimmerDataProvider.notifier).uploadProfilePhoto(
          fileName: picked.fileName,
          bytes: picked.bytes,
        );
    if (!mounted) return;
    setState(() => _isUploadingPhoto = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Profile photo updated.'
              : 'Could not upload profile photo: $error',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final logs = data.raceLogs;
        final meetResults = data.meetResults;
        final personalBests = data.personalBests;

        final subscription = ref.watch(subscriptionStateProvider).value;
        final showProFeatures = subscription != null &&
            SubscriptionCapabilities.canUseProFeatures(subscription);

        final snapshot = data.passportSnapshot(swimmer);
        final daily = SwimIqDailyProgress.calculate(
          raceLogs: logs,
          meetResults: meetResults,
          videos: data.userFacingVideos,
          goals: data.goals,
          overallSwimIqScore: data.swimIqScore,
        );
        final badges = SwimIqBadgeCatalog.evaluate(
          daily: daily,
          raceLogs: logs,
          meetResults: meetResults,
          goals: data.goals,
          personalBests: personalBests,
          videos: data.userFacingVideos,
          analyses: data.userFacingVideoAnalyses,
          profile: data.profile,
          snapshot: snapshot,
        );

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _DashboardHero(
              displayName: data.displayName(swimmer),
              swimIqScore: data.swimIqScore,
              highestCut: showProFeatures
                  ? snapshot.highestCut
                  : (logs.isEmpty ? 'Log swims to score' : 'Upgrade for cuts'),
              climbPercent: daily.scoreRopeClimbPercent,
              profilePhotoUrl: data.profile?.profilePhotoUrl,
              isUploadingPhoto: _isUploadingPhoto,
              onUploadPhoto: _uploadProfilePhoto,
            ),
            const SizedBox(height: 16),
            SwimIqRopeClimbCard(daily: daily, badges: badges),
            const SizedBox(height: 12),
            const DashboardMembershipPlansCard(),
            const SizedBox(height: 16),
            _EventCutsProgressSection(
              personalBests: personalBests,
              raceLogs: logs,
              catalog: data.motivationalStandards,
              profile: data.profile,
              showProFeatures: showProFeatures,
              highestCut: snapshot.highestCut,
              onOpenMeetsTab: () {
                ref.read(trainingLogSegmentProvider.notifier).state = 1;
                ref.read(homeTabIndexProvider.notifier).state = HomeTab.trainingLog;
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.displayName,
    required this.swimIqScore,
    required this.highestCut,
    required this.climbPercent,
    this.profilePhotoUrl,
    this.isUploadingPhoto = false,
    this.onUploadPhoto,
  });

  final String displayName;
  final int swimIqScore;
  final String highestCut;
  final int climbPercent;
  final String? profilePhotoUrl;
  final bool isUploadingPhoto;
  final VoidCallback? onUploadPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDeep,
            AppColors.primary,
            AppColors.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$swimIqScore',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'SwimIQ Score',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroChip(label: 'Highest cut: $highestCut'),
                    _HeroChip(label: '$climbPercent% up the rope'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _DashboardPhotoUpload(
            photoUrl: profilePhotoUrl,
            isUploading: isUploadingPhoto,
            onUpload: onUploadPhoto,
          ),
        ],
      ),
    );
  }
}

class _DashboardPhotoUpload extends StatelessWidget {
  const _DashboardPhotoUpload({
    this.photoUrl,
    this.isUploading = false,
    this.onUpload,
  });

  final String? photoUrl;
  final bool isUploading;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    const size = 120.0;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isUploading ? null : onUpload,
            customBorder: const CircleBorder(),
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasPhoto)
                      Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.15),
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_outline,
                          color: Colors.white70,
                          size: 52,
                        ),
                      )
                    else
                      const Icon(
                        Icons.person_outline,
                        color: Colors.white70,
                        size: 52,
                      ),
                    if (isUploading)
                      Container(
                        color: Colors.black45,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          color: Colors.black54,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Icon(
                            hasPhoto
                                ? Icons.photo_camera_outlined
                                : Icons.add_a_photo_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: isUploading ? null : onUpload,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            isUploading
                ? 'Uploading...'
                : (hasPhoto ? 'Change photo' : 'Upload photo'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EventCutsProgressSection extends StatelessWidget {
  const _EventCutsProgressSection({
    required this.personalBests,
    required this.raceLogs,
    required this.catalog,
    required this.profile,
    required this.showProFeatures,
    required this.highestCut,
    required this.onOpenMeetsTab,
  });

  final List<PersonalBestEntry> personalBests;
  final List<RaceLog> raceLogs;
  final UsaMotivationalStandardsCatalog catalog;
  final SwimmerProfile? profile;
  final bool showProFeatures;
  final String highestCut;
  final VoidCallback onOpenMeetsTab;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Events & USA cuts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Top times and motivational standards per event.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 14),
            if (showProFeatures && personalBests.isNotEmpty)
              ...personalBests.take(8).map((pb) {
                final cut = MotivationalCut.labelForSwim(
                  catalog: catalog,
                  profile: profile,
                  stroke: pb.stroke,
                  distance: pb.distance,
                  course: pb.course,
                  timeSeconds: pb.timeSeconds,
                );
                return _EventProgressTile(
                  title: pb.displayTitle,
                  subtitle:
                      '${pb.course} · ${pb.formattedTime} · ${dateFormat.format(pb.date)}',
                  cutLabel: cut,
                  highlight: cut == highestCut,
                );
              })
            else if (!showProFeatures && raceLogs.isNotEmpty)
              ..._sessionSummaries(raceLogs, dateFormat)
            else
              EmptyStateMessage(
                message: showProFeatures
                    ? 'No official meet times yet. Log meets to unlock your cuts chart.'
                    : 'Log training sessions to see your stroke mix chart.',
              ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: DashboardCutsPieChart(
                    personalBests: personalBests,
                    raceLogs: raceLogs,
                    catalog: catalog,
                    profile: profile,
                    showProFeatures: showProFeatures,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 28),
                      FilledButton.tonalIcon(
                        onPressed: onOpenMeetsTab,
                        icon: const Icon(Icons.stadium_outlined, size: 20),
                        label: const Text('Log meets'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add official meet times & heat sheets.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sessionSummaries(List<RaceLog> logs, DateFormat dateFormat) {
    final sorted = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    final byEvent = <String, RaceLog>{};
    for (final log in sorted) {
      final key = '${log.distance} ${log.stroke} (${log.course})';
      final existing = byEvent[key];
      if (existing == null || log.timeSeconds < existing.timeSeconds) {
        byEvent[key] = log;
      }
    }
    return byEvent.entries.map((entry) {
      final log = entry.value;
      return _EventProgressTile(
        title: entry.key,
        subtitle: 'Best session · ${dateFormat.format(log.date)}',
        cutLabel: SwimTime.fromSeconds(log.timeSeconds),
        highlight: false,
      );
    }).toList();
  }
}

class _EventProgressTile extends StatelessWidget {
  const _EventProgressTile({
    required this.title,
    required this.subtitle,
    required this.cutLabel,
    required this.highlight,
  });

  final String title;
  final String subtitle;
  final String cutLabel;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.45)
              : Colors.grey.shade200,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              cutLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDeep,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
