import 'package:flutter/material.dart';

import '../core/recruiting/recruiting_card_insights.dart';
import '../core/theme/app_theme.dart';
import '../data/models/personal_best_entry.dart';

/// Compact on-screen preview of the printable SwimIQ recruiting card.
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
    this.email,
    this.phone,
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
  final String? gpa;
  final String? website;
  final String? email;
  final String? phone;
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
        graduationYear != null ? 'Class of $graduationYear' : 'Add grad year';
    final scoreText = swimIqScore > 0 ? '$swimIqScore' : '—';
    final cutValue = _cutDisplayValue(highestCut);
    final nameLine =
        displayName.trim().isEmpty ? 'Add athlete name' : displayName.trim();
    final websiteLine = _contactOrPlaceholder(website, 'Add website');
    final emailLine = _contactOrPlaceholder(email, 'Add email');
    final phoneLine = _contactOrPlaceholder(phone, 'Add phone');
    final gpaLine = gpa?.trim().isNotEmpty == true ? gpa!.trim() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AspectRatio(
              aspectRatio: 3.5 / 2.35,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
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
                      color: AppColors.primaryDeep.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              'SWIMIQ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  insights.achievementBadge.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CardPhoto(
                              photoUrl: profilePhotoUrl,
                              onUpload: onUploadPhoto,
                              isUploading: isUploadingPhoto,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nameLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$gradLine · $teamLine',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        scoreText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          height: 0.95,
                                          letterSpacing: -0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 2),
                                        child: Text(
                                          'SwimIQ\nScore',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.85),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 8,
                                            height: 1.05,
                                          ),
                                        ),
                                      ),
                                      if (gpaLine != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'GPA $gpaLine',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _ContactLine(
                                      icon: Icons.language,
                                      value: websiteLine,
                                    ),
                                    _ContactLine(
                                      icon: Icons.email_outlined,
                                      value: emailLine,
                                    ),
                                    _ContactLine(
                                      icon: Icons.phone_outlined,
                                      value: phoneLine,
                                    ),
                                    const SizedBox(height: 3),
                                    _PbLine(label: '1', value: eventOne),
                                    const SizedBox(height: 2),
                                    _PbLine(label: '2', value: eventTwo),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 4,
                                child: _HighestCutPanel(cutValue: cutValue),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 11,
                                color: AppColors.accent.withValues(alpha: 0.95),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  insights.highlight,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10.5,
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
          ),
        ),
        if (onUploadPhoto != null) ...[
          const SizedBox(height: 6),
          TextButton.icon(
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
                      ? 'Change photo'
                      : 'Add photo'),
            ),
          ),
        ],
      ],
    );
  }

  static String _contactOrPlaceholder(String? value, String placeholder) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? placeholder : text;
  }

  static String _cutDisplayValue(String highestCut) {
    final cut = highestCut.trim();
    if (cut.isEmpty ||
        cut.toLowerCase().contains('log') ||
        cut.toLowerCase().contains('setup') ||
        cut.toLowerCase().contains('no motivational')) {
      return '—';
    }
    // Prefer short motivational letters (AAAA/AAA/AA/A/BB/B).
    final match = RegExp(r'\b(AAAA|AAA|AA|A|BB|B)\b', caseSensitive: false)
        .firstMatch(cut);
    if (match != null) return match.group(1)!.toUpperCase();
    return cut;
  }
}

class _HighestCutPanel extends StatelessWidget {
  const _HighestCutPanel({required this.cutValue});

  final String cutValue;

  @override
  Widget build(BuildContext context) {
    final pending = cutValue == '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'HIGHEST USA CUT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w900,
              fontSize: 7.5,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            cutValue,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: pending ? 18 : 26,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            pending ? 'Add meet PBs' : 'Motivational standard',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
              fontSize: 8.5,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value.toLowerCase().startsWith('add ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.5),
      child: Row(
        children: [
          Icon(
            icon,
            size: 11,
            color: Colors.white.withValues(alpha: isPlaceholder ? 0.55 : 0.9),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    Colors.white.withValues(alpha: isPlaceholder ? 0.62 : 0.95),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPhoto extends StatelessWidget {
  const _CardPhoto({
    this.photoUrl,
    this.onUpload,
    this.isUploading = false,
  });

  final String? photoUrl;
  final VoidCallback? onUpload;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    const size = 52.0;
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
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipOval(
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      color: Colors.white70,
                      size: 24,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white70, size: 24),
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
          width: 15,
          height: 15,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 9,
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
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
