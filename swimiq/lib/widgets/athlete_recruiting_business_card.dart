import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/models/personal_best_entry.dart';

/// Full-width exportable recruiting card — name + SwimIQ score left, large photo right.
class AthleteRecruitingBusinessCard extends StatelessWidget {
  const AthleteRecruitingBusinessCard({
    super.key,
    required this.displayName,
    required this.swimIqScore,
    required this.highestCut,
    required this.team,
    required this.gpa,
    required this.website,
    required this.topEvents,
    this.graduationYear,
    this.profilePhotoUrl,
    this.usaSwimmingId,
    this.isUploadingPhoto = false,
    this.onUploadPhoto,
  });

  final String displayName;
  final int swimIqScore;
  final String highestCut;
  final String? team;
  final String? gpa;
  final String? website;
  final List<String> topEvents;
  final int? graduationYear;
  final String? profilePhotoUrl;
  final String? usaSwimmingId;
  final bool isUploadingPhoto;
  final VoidCallback? onUploadPhoto;

  static List<String> topEventLines(List<PersonalBestEntry> personalBests) {
    if (personalBests.isEmpty) return const [];
    return personalBests
        .take(2)
        .map((pb) => '${pb.displayTitle} ${pb.formattedTime} (${pb.course})')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final eventOne = topEvents.isNotEmpty
        ? topEvents.first
        : 'Log a meet result to feature your best event';
    final eventTwo = topEvents.length > 1
        ? topEvents[1]
        : 'Add a second PB for coaches to compare';
    final scoreText = swimIqScore > 0 ? '$swimIqScore' : '—';
    final cutLabel = highestCut.trim().isNotEmpty &&
            !highestCut.toLowerCase().contains('log')
        ? highestCut.trim()
        : 'Cuts unlock after meet results';

    return LayoutBuilder(
      builder: (context, constraints) {
        final photoSize = constraints.maxWidth >= 520
            ? 148.0
            : constraints.maxWidth >= 380
                ? 120.0
                : 96.0;
        final scoreSize = constraints.maxWidth >= 420 ? 56.0 : 44.0;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF020812),
                Color(0xFF0A3A6E),
                AppColors.primaryDeep,
                AppColors.primary,
              ],
              stops: [0.0, 0.35, 0.72, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDeep.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF7DD3FC),
                          Color(0xFF38B6FF),
                          Color(0xFFFFFFFF),
                          Color(0xFF38B6FF),
                          Color(0xFF7DD3FC),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -36,
                  top: 40,
                  child: Icon(
                    Icons.pool,
                    size: 200,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: -30,
                  child: Icon(
                    Icons.water,
                    size: 160,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Text(
                              'SWIMIQ · RECRUITING CARD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Athlete Passport',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  team?.trim().isNotEmpty == true
                                      ? team!.trim()
                                      : 'Your team — add it in Athlete Details',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.92),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                if (graduationYear != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Class of $graduationYear',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      scoreText,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: scoreSize,
                                        fontWeight: FontWeight.w900,
                                        height: 0.95,
                                        letterSpacing: -1.5,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'SwimIQ Score',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.9),
                                              fontWeight: FontWeight.w800,
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
                                    _HeroPill(label: 'Highest cut: $cutLabel'),
                                    _HeroPill(
                                      label: usaSwimmingId?.trim().isNotEmpty ==
                                              true
                                          ? 'USA: ${usaSwimmingId!.trim()}'
                                          : 'USA ID — add in passport',
                                      muted: usaSwimmingId?.trim().isEmpty !=
                                          false,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          _ProfilePhotoPanel(
                            photoUrl: profilePhotoUrl,
                            size: photoSize,
                            isUploading: isUploadingPhoto,
                            onUpload: onUploadPhoto,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Top event',
                              value: eventOne,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatTile(
                              label: '2nd event',
                              value: eventTwo,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _FooterChip(
                              icon: Icons.school_outlined,
                              label: 'GPA',
                              value: gpa?.trim().isNotEmpty == true
                                  ? gpa!.trim()
                                  : 'Add GPA below',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _FooterChip(
                              icon: Icons.language_outlined,
                              label: 'Recruiting site',
                              value: website?.trim().isNotEmpty == true
                                  ? website!.trim()
                                  : 'Add website below',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '© 2026 SwimIQ LLC · Built for the next level',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfilePhotoPanel extends StatelessWidget {
  const _ProfilePhotoPanel({
    this.photoUrl,
    this.size = 148,
    this.isUploading = false,
    this.onUpload,
  });

  final String? photoUrl;
  final double size;
  final bool isUploading;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PhotoMark(photoUrl: photoUrl, size: size),
        if (onUpload != null) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: isUploading ? null : onUpload,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            icon: isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.photo_camera_outlined, size: 18),
            label: Text(
              isUploading
                  ? 'Uploading…'
                  : (photoUrl?.isNotEmpty == true
                      ? 'Change photo'
                      : 'Upload photo'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: muted ? 0.1 : 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: muted ? 0.7 : 1),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PhotoMark extends StatelessWidget {
  const _PhotoMark({
    this.photoUrl,
    this.size = 44,
  });

  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              alignment: const Alignment(0, -0.15),
              errorBuilder: (_, __, ___) => Icon(
                Icons.person_outline,
                color: Colors.white70,
                size: size * 0.42,
              ),
            )
          : Icon(
              Icons.person_outline,
              color: Colors.white70,
              size: size * 0.42,
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontSize: 10,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 13 : 16,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _FooterChip extends StatelessWidget {
  const _FooterChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
