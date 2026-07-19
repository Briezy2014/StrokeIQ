import 'package:flutter/material.dart';

import '../core/recruiting/recruiting_card_insights.dart';
import '../core/theme/app_theme.dart';
import '../data/models/personal_best_entry.dart';

/// On-screen preview of the wallet-sized SwimIQ recruiting card (3.5" × 2").
class AthleteRecruitingBusinessCard extends StatelessWidget {
  const AthleteRecruitingBusinessCard({
    super.key,
    required this.displayName,
    required this.swimIqScore,
    required this.highestCut,
    required this.team,
    required this.topEvents,
    this.graduationYear,
    this.profilePhotoUrl,
    this.isUploadingPhoto = false,
    this.onUploadPhoto,
    this.gpa,
    this.website,
    this.usaSwimmingId,
  });

  final String displayName;
  final int swimIqScore;
  final String highestCut;
  final String? team;
  final List<String> topEvents;
  final int? graduationYear;
  final String? profilePhotoUrl;
  final bool isUploadingPhoto;
  final VoidCallback? onUploadPhoto;

  /// Kept for call-site compatibility; not shown on the wallet card.
  final String? gpa;
  final String? website;
  final String? usaSwimmingId;

  static List<String> topEventLines(List<PersonalBestEntry> personalBests) {
    if (personalBests.isEmpty) return const [];
    return personalBests
        .take(2)
        .map((pb) => '${pb.displayTitle}  ${pb.formattedTime}')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final insights = RecruitingCardInsights.from(
      highestCut: highestCut,
      topEvents: topEvents,
      swimIqScore: swimIqScore,
    );
    final eventOne = topEvents.isNotEmpty ? topEvents.first : 'Add top PB';
    final eventTwo = topEvents.length > 1 ? topEvents[1] : 'Add 2nd PB';
    final teamLine =
        team?.trim().isNotEmpty == true ? team!.trim() : 'Add club / team';
    final gradLine =
        graduationYear != null ? 'Class of $graduationYear' : 'Grad year';
    final scoreText = swimIqScore > 0 ? '$swimIqScore' : '—';
    final cutLine = highestCut.trim().isNotEmpty &&
            !highestCut.toLowerCase().contains('log')
        ? highestCut.trim()
        : 'Cut pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 3.5 / 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF041526),
                  Color(0xFF0B3D6E),
                  AppColors.primaryDeep,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDeep.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'SWIMIQ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            insights.achievementBadge.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _WalletPhoto(
                            photoUrl: profilePhotoUrl,
                            isUploading: isUploadingPhoto,
                            onUpload: onUploadPhoto,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$gradLine  ·  $teamLine',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      scoreText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 34,
                                        height: 0.9,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        'SwimIQ\nScore',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      child: Text(
                                        cutLine,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                _PbLine(label: '1', value: eventOne),
                                const SizedBox(height: 4),
                                _PbLine(label: '2', value: eventTwo),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: AppColors.accent.withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              insights.highlight,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (onUploadPhoto != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: isUploadingPhoto ? null : onUploadPhoto,
              icon: isUploadingPhoto
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(
                isUploadingPhoto
                    ? 'Uploading photo…'
                    : (profilePhotoUrl?.isNotEmpty == true
                        ? 'Change profile photo'
                        : 'Add profile photo'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WalletPhoto extends StatelessWidget {
  const _WalletPhoto({
    this.photoUrl,
    this.isUploading = false,
    this.onUpload,
  });

  final String? photoUrl;
  final bool isUploading;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    const size = 78.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUploading ? null : onUpload,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      color: Colors.white70,
                      size: 34,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white70, size: 34),
          ),
        ),
      ),
    );
  }
}

class _PbLine extends StatelessWidget {
  const _PbLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}
