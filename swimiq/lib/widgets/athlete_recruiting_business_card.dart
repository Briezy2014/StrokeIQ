import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/models/personal_best_entry.dart';

/// Wallet-sized recruiting card — always shows key fields with sensible fallbacks.
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
        : 'Top event — log a meet result';
    final eventTwo = topEvents.length > 1
        ? topEvents[1]
        : 'Second event — add another PB';

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF020812),
            AppColors.primaryDeep,
            AppColors.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -10,
              child: Icon(
                Icons.water_drop,
                size: 120,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                    Row(
                      children: [
                        _PhotoMark(photoUrl: profilePhotoUrl, size: 58),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                team?.trim().isNotEmpty == true
                                    ? team!.trim()
                                    : 'Add swim team in passport',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              if (graduationYear != null)
                                Text(
                                  'Class of $graduationYear',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'USA Swimming',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                            ),
                            Text(
                              usaSwimmingId?.trim().isNotEmpty == true
                                  ? usaSwimmingId!.trim()
                                  : 'Add ID in passport',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: usaSwimmingId?.trim().isNotEmpty == true
                                        ? AppColors.accent
                                        : Colors.white.withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'SwimIQ Score',
                            value: swimIqScore > 0 ? '$swimIqScore' : '—',
                            accent: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatTile(
                            label: 'Highest Cut',
                            value: highestCut,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoMark extends StatelessWidget {
  const _PhotoMark({
    this.photoUrl,
    this.size = 44,
    this.onLight = false,
  });

  final String? photoUrl;
  final double size;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final borderColor = onLight
        ? AppColors.primary.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.5);
    final fillColor = onLight
        ? AppColors.primary.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.12);
    final iconColor = onLight ? AppColors.primaryDeep : Colors.white70;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: Border.all(color: borderColor, width: size >= 72 ? 2.5 : 1.5),
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
                color: iconColor,
                size: size * 0.5,
              ),
            )
          : Icon(
              Icons.person_outline,
              color: iconColor,
              size: size * 0.48,
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.accent = false,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: accent
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent
              ? AppColors.accent.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.2),
        ),
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
                  fontSize: 9,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 11 : 16,
                  height: 1.15,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

/// Compact identity strip for the left side of the passport header row.
class AthletePassportIdentityCard extends StatelessWidget {
  const AthletePassportIdentityCard({
    super.key,
    required this.displayName,
    this.team,
    this.coach,
    this.primaryStroke,
    this.graduationYear,
    this.profilePhotoUrl,
    this.isUploadingPhoto = false,
    this.onUploadPhoto,
  });

  final String displayName;
  final String? team;
  final String? coach;
  final String? primaryStroke;
  final int? graduationYear;
  final String? profilePhotoUrl;
  final bool isUploadingPhoto;
  final VoidCallback? onUploadPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.surfaceLight,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PhotoMark(
                photoUrl: profilePhotoUrl,
                size: 108,
                onLight: true,
              ),
              if (onUploadPhoto != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: isUploadingPhoto ? null : onUploadPhoto,
                  icon: isUploadingPhoto
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_outlined, size: 16),
                  label: Text(
                    isUploadingPhoto ? 'Uploading…' : 'Profile photo',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Athlete Passport',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                ),
                if (team?.trim().isNotEmpty == true)
                  Text(
                    team!.trim(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark.withValues(alpha: 0.8),
                        ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _detailLine(
                    coach: coach,
                    stroke: primaryStroke,
                    graduationYear: graduationYear,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.7),
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _detailLine({
    String? coach,
    String? stroke,
    int? graduationYear,
  }) {
    final parts = <String>[];
    if (coach?.trim().isNotEmpty == true) parts.add('Coach: ${coach!.trim()}');
    if (stroke?.trim().isNotEmpty == true) {
      parts.add('${stroke!.trim()} specialist');
    }
    if (graduationYear != null) parts.add('Class of $graduationYear');
    return parts.isEmpty ? 'Complete passport fields below' : parts.join(' · ');
  }
}
