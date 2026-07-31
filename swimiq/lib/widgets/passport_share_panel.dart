import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/passport_metrics.dart';
import '../data/models/swimmer_profile.dart';
import 'athlete_recruiting_business_card.dart';
import 'passport_full_export_bar.dart';
import 'recruiting_card_export_bar.dart';

/// One Share & print block: wallet-card preview first, then two clearly
/// labeled export rows (wallet card vs full passport packet).
class PassportSharePanel extends StatelessWidget {
  const PassportSharePanel({
    super.key,
    required this.cardSnapshot,
    required this.passportSnapshot,
    required this.profile,
    required this.displayName,
    required this.fileSafeName,
    required this.topEvents,
    this.isUploadingPhoto = false,
    this.onUploadPhoto,
  });

  final RecruitingCardSnapshot cardSnapshot;
  final PassportSnapshot passportSnapshot;
  final SwimmerProfile? profile;
  final String displayName;
  final String fileSafeName;
  final List<String> topEvents;
  final bool isUploadingPhoto;
  final VoidCallback? onUploadPhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Share & print',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDeep,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Preview your wallet card, then export the short handout or the '
          'full coach packet.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
                height: 1.35,
              ),
        ),
        const SizedBox(height: 14),
        AthleteRecruitingBusinessCard(
          displayName: displayName,
          swimIqScore: cardSnapshot.swimIqScore,
          highestCut: cardSnapshot.highestCut,
          team: cardSnapshot.team,
          gpa: cardSnapshot.gpa,
          website: cardSnapshot.website,
          email: cardSnapshot.email,
          phone: cardSnapshot.phone,
          coach: cardSnapshot.coach,
          graduationYear: cardSnapshot.graduationYear,
          profilePhotoUrl: cardSnapshot.profilePhotoUrl,
          usaSwimmingId: cardSnapshot.usaSwimmingId,
          topEvents: topEvents,
          isUploadingPhoto: isUploadingPhoto,
          onUploadPhoto: onUploadPhoto,
        ),
        const SizedBox(height: 14),
        _ShareOptionRow(
          title: 'Wallet card',
          subtitle: 'One-page recruiting handout — what coaches see first.',
          child: RecruitingCardExportBar(
            snapshot: cardSnapshot,
            showLabels: false,
          ),
        ),
        const SizedBox(height: 10),
        _ShareOptionRow(
          title: 'Full passport packet',
          subtitle:
              'Multi-page PDF: status, Power Index, times, goals, academics, '
              'and coaching notes.',
          child: PassportFullExportBar(
            snapshot: passportSnapshot,
            profile: profile,
            displayName: displayName,
            fileSafeName: fileSafeName,
            showHeader: false,
          ),
        ),
      ],
    );
  }
}

class _ShareOptionRow extends StatelessWidget {
  const _ShareOptionRow({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
