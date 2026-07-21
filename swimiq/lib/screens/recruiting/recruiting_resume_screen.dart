import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/recruiting/recruiting_resume_builder.dart';
import '../../core/recruiting/recruiting_resume_pdf.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/personal_best_entry.dart';
import '../../data/models/swimmer_profile.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swim_iq_feature_scaffold.dart';
import '../../widgets/swimmer_screen.dart';

/// Pro-tier one-page recruiting résumé with PDF export.
class RecruitingResumeScreen extends ConsumerStatefulWidget {
  const RecruitingResumeScreen({super.key});

  @override
  ConsumerState<RecruitingResumeScreen> createState() =>
      _RecruitingResumeScreenState();
}

class _RecruitingResumeScreenState extends ConsumerState<RecruitingResumeScreen> {
  String? _resumeText;
  SwimmerProfile? _profile;
  String? _displayName;
  List<PersonalBestEntry> _personalBests = const [];
  int _swimIqScore = 0;
  String _highestCut = '';
  String _powerIndexLine = '';
  List<String> _championshipTags = const [];

  @override
  Widget build(BuildContext context) {
    return SwimIqFeatureScaffold(
      title: 'Best Times Résumé',
      body: SubscriptionGatedScreen(
        minimumTier: SubscriptionTier.pro,
        title: 'Unlock SwimIQ Pro',
        message: 'Best Times Résumé is included with Pro.',
        teaserFeatures: const [
          'Auto-generated recruiting résumé',
          'Top times, honors & academics',
          'Export PDF for college coaches',
        ],
        child: SwimmerScreen(
          builder: (context, ref, data, swimmer) {
            final snapshot = data.passportSnapshot(swimmer);
            final tags = RecruitingResumeBuilder.championshipTags(
              highestCut: snapshot.highestCut,
              personalBests: data.personalBests,
            );
            final powerIndexLine = snapshot.powerIndex.resumeValue;
            final resume = RecruitingResumeBuilder.buildText(
              profile: data.profile,
              displayName: data.displayName(swimmer),
              personalBests: data.personalBests,
              swimIqScore: snapshot.swimIqScore,
              highestCut: snapshot.highestCut,
              championshipsQualified: tags,
              powerIndexLine: powerIndexLine,
            );

            _resumeText = resume;
            _profile = data.profile;
            _displayName = data.displayName(swimmer);
            _personalBests = data.personalBests;
            _swimIqScore = snapshot.swimIqScore;
            _highestCut = snapshot.highestCut;
            _powerIndexLine = powerIndexLine;
            _championshipTags = tags;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const _ResumePageHeader(),
                const SizedBox(height: 16),
                _ResumeDocument(
                  displayName: data.displayName(swimmer),
                  profile: data.profile,
                  personalBests: data.personalBests,
                  swimIqScore: snapshot.swimIqScore,
                  highestCut: snapshot.highestCut,
                  powerIndexLine: powerIndexLine,
                  championshipTags: tags,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyResume(context),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy text'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _exportPdf(context, swimmer),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Export PDF'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _previewPdf(context),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print / preview PDF'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Share the PDF with college coaches. Edit contact details and '
                  'website in Athlete Passport so links stay current.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _copyResume(BuildContext context) async {
    final text = _resumeText;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Résumé copied to clipboard.')),
    );
  }

  Future<Uint8List?> _pdfBytes() async {
    final bytes = await RecruitingResumePdf.buildBytes(
      profile: _profile,
      displayName: _displayName ?? 'Athlete',
      personalBests: _personalBests,
      swimIqScore: _swimIqScore,
      highestCut: _highestCut,
      championshipsQualified: _championshipTags,
      powerIndexLine: _powerIndexLine,
    );
    return Uint8List.fromList(bytes);
  }

  Future<void> _exportPdf(BuildContext context, String swimmer) async {
    try {
      final bytes = await _pdfBytes();
      if (bytes == null || !context.mounted) return;
      final safeName = swimmer.replaceAll(RegExp(r'[^\w\-]'), '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'SwimIQ_Resume_$safeName.pdf',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF ready — choose Save or Share.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export PDF: $e')),
      );
    }
  }

  Future<void> _previewPdf(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) async => (await _pdfBytes()) ?? Uint8List(0),
        name: 'SwimIQ_Recruiting_Resume',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open print preview: $e')),
      );
    }
  }
}

class _ResumePageHeader extends StatelessWidget {
  const _ResumePageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Best Times Résumé',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'A coach-ready recruiting page — top times, academics, and contact links in one view.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeDocument extends StatelessWidget {
  const _ResumeDocument({
    required this.displayName,
    required this.profile,
    required this.personalBests,
    required this.swimIqScore,
    required this.highestCut,
    required this.powerIndexLine,
    required this.championshipTags,
  });

  final String displayName;
  final SwimmerProfile? profile;
  final List<PersonalBestEntry> personalBests;
  final int swimIqScore;
  final String highestCut;
  final String powerIndexLine;
  final List<String> championshipTags;

  @override
  Widget build(BuildContext context) {
    final name = profile?.recruitingCardName(fallbackSwimmerKey: displayName) ??
        displayName;
    final website = profile?.athleteWebsite?.trim();
    final email = profile?.athleteEmail?.trim();
    final phone = profile?.athletePhone?.trim();
    final coachEmail =
        (profile?.coachEmail ?? profile?.recruitingEmail)?.trim();

    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IdentityBanner(
            name: name,
            team: profile?.team,
            school: profile?.school,
            graduationYear: profile?.graduationYear,
            photoUrl: profile?.profilePhotoUrl,
            swimIqScore: swimIqScore,
            highestCut: highestCut,
            primaryStroke: profile?.primaryStroke,
            favoriteEvent: profile?.favoriteEvent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final profileColumn = _ProfileColumn(
                  profile: profile,
                  website: website,
                  email: email,
                  phone: phone,
                  coachEmail: coachEmail,
                );
                final timesColumn = _TimesColumn(personalBests: personalBests);

                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      profileColumn,
                      const SizedBox(height: 16),
                      timesColumn,
                      const SizedBox(height: 16),
                      _SnapshotStrip(
                        swimIqScore: swimIqScore,
                        highestCut: highestCut,
                        powerIndexLine: powerIndexLine,
                      ),
                      const SizedBox(height: 16),
                      _HonorsColumn(
                        profile: profile,
                        championshipTags: championshipTags,
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: profileColumn),
                        const SizedBox(width: 16),
                        Expanded(flex: 6, child: timesColumn),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SnapshotStrip(
                      swimIqScore: swimIqScore,
                      highestCut: highestCut,
                      powerIndexLine: powerIndexLine,
                    ),
                    const SizedBox(height: 16),
                    _HonorsColumn(
                      profile: profile,
                      championshipTags: championshipTags,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityBanner extends StatelessWidget {
  const _IdentityBanner({
    required this.name,
    required this.team,
    required this.school,
    required this.graduationYear,
    required this.photoUrl,
    required this.swimIqScore,
    required this.highestCut,
    required this.primaryStroke,
    required this.favoriteEvent,
  });

  final String name;
  final String? team;
  final String? school;
  final int? graduationYear;
  final String? photoUrl;
  final int swimIqScore;
  final String highestCut;
  final String? primaryStroke;
  final String? favoriteEvent;

  @override
  Widget build(BuildContext context) {
    final cutLabel = highestCut.trim().isEmpty ||
            highestCut.toLowerCase().contains('log') ||
            highestCut.toLowerCase().contains('setup')
        ? 'Cut pending'
        : highestCut;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF041526),
            Color(0xFF0B3D6E),
            AppColors.primaryDeep,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResumePhoto(photoUrl: photoUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SWIMIQ RECRUITING RÉSUMÉ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (graduationYear != null) 'Class of $graduationYear',
                    if (team?.trim().isNotEmpty == true) team!.trim(),
                    if (school?.trim().isNotEmpty == true) school!.trim(),
                  ].join(' · '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (primaryStroke?.trim().isNotEmpty == true ||
                    favoriteEvent?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (primaryStroke?.trim().isNotEmpty == true)
                        'Primary: ${primaryStroke!.trim()}',
                      if (favoriteEvent?.trim().isNotEmpty == true)
                        'Favorite: ${favoriteEvent!.trim()}',
                    ].join(' · '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _BannerChip(
                      label: swimIqScore > 0
                          ? 'SwimIQ $swimIqScore'
                          : 'SwimIQ —',
                    ),
                    _BannerChip(label: 'Highest cut $cutLabel'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumePhoto extends StatelessWidget {
  const _ResumePhoto({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2),
        color: Colors.white.withValues(alpha: 0.12),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? const Icon(Icons.person, color: Colors.white70, size: 40)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.person, color: Colors.white70, size: 40),
            ),
    );
  }
}

class _BannerChip extends StatelessWidget {
  const _BannerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
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

class _ProfileColumn extends StatelessWidget {
  const _ProfileColumn({
    required this.profile,
    required this.website,
    required this.email,
    required this.phone,
    required this.coachEmail,
  });

  final SwimmerProfile? profile;
  final String? website;
  final String? email;
  final String? phone;
  final String? coachEmail;

  @override
  Widget build(BuildContext context) {
    return _ResumeSection(
      title: 'Athlete profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoGrid(
            items: [
              _InfoItem('Graduation', profile?.graduationYear?.toString()),
              _InfoItem('Recruiting status', profile?.recruitingStatus),
              _InfoItem('Club team', profile?.team),
              _InfoItem('High school', profile?.school),
              _InfoItem('Coach', profile?.coachName),
              _InfoItem('Coach phone', profile?.coachPhone),
              _InfoItem('USA Swimming ID', profile?.usaSwimmingId),
              _InfoItem('GPA', profile?.gpa),
              _InfoItem('SAT', profile?.satScore),
              _InfoItem('ACT', profile?.actScore),
              _InfoItem('Intended major', profile?.intendedMajor),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Contact',
            style: TextStyle(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          _LinkRow(
            icon: Icons.language,
            label: 'Website',
            value: website,
            kind: _LinkKind.web,
          ),
          _LinkRow(
            icon: Icons.email_outlined,
            label: 'Athlete email',
            value: email,
            kind: _LinkKind.email,
          ),
          _LinkRow(
            icon: Icons.phone_outlined,
            label: 'Athlete phone',
            value: phone,
            kind: _LinkKind.phone,
          ),
          _LinkRow(
            icon: Icons.mail_outline,
            label: 'Coach email',
            value: coachEmail,
            kind: _LinkKind.email,
          ),
        ],
      ),
    );
  }
}

class _TimesColumn extends StatelessWidget {
  const _TimesColumn({required this.personalBests});

  final List<PersonalBestEntry> personalBests;

  @override
  Widget build(BuildContext context) {
    return _ResumeSection(
      title: 'Top times',
      child: personalBests.isEmpty
          ? Text(
              'No official meet times yet. Upload best times on the PBs tab.',
              style: TextStyle(
                color: AppColors.textDark.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            )
          : Column(
              children: [
                for (final pb in personalBests.take(12))
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pb.displayTitle,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                pb.course,
                                style: TextStyle(
                                  color: AppColors.textDark
                                      .withValues(alpha: 0.65),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          pb.formattedTime,
                          style: const TextStyle(
                            color: AppColors.primaryDeep,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
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

class _SnapshotStrip extends StatelessWidget {
  const _SnapshotStrip({
    required this.swimIqScore,
    required this.highestCut,
    required this.powerIndexLine,
  });

  final int swimIqScore;
  final String highestCut;
  final String powerIndexLine;

  @override
  Widget build(BuildContext context) {
    final powerLabel = powerIndexLine.trim().isEmpty
        ? '—'
        : (powerIndexLine.contains('/')
            ? powerIndexLine.split('·').first.trim()
            : powerIndexLine);
    return _ResumeSection(
      title: 'Performance snapshot',
      child: Row(
        children: [
          Expanded(
            child: _MetricTile(
              label: 'SwimIQ',
              value: swimIqScore > 0 ? '$swimIqScore' : '—',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricTile(
              label: 'Highest cut',
              value: highestCut.trim().isEmpty ? '—' : highestCut,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricTile(
              label: 'Power Index',
              value: powerLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _HonorsColumn extends StatelessWidget {
  const _HonorsColumn({
    required this.profile,
    required this.championshipTags,
  });

  final SwimmerProfile? profile;
  final List<String> championshipTags;

  @override
  Widget build(BuildContext context) {
    final academic = profile?.academicHonors?.trim();
    final athletic = profile?.athleticHonors?.trim();
    final leadership = profile?.leadershipService?.trim();
    final interests = profile?.collegeInterests?.trim();
    final other = profile?.otherInterests?.trim();

    final bullets = <String>[
      if (academic?.isNotEmpty == true) 'Academics: $academic',
      if (athletic?.isNotEmpty == true) 'Athletics: $athletic',
      if (leadership?.isNotEmpty == true) 'Leadership: $leadership',
      if (interests?.isNotEmpty == true) 'College interests: $interests',
      if (other?.isNotEmpty == true) 'Other interests: $other',
      ...championshipTags.take(5),
    ];

    return _ResumeSection(
      title: 'Awards, honors & interests',
      child: bullets.isEmpty
          ? Text(
              'Add honors and college interests in Athlete Passport to fill this section.',
              style: TextStyle(
                color: AppColors.textDark.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
              ),
            )
          : Column(
              children: [
                for (final bullet in bullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: AppColors.primaryDeep.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            bullet,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
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

class _ResumeSection extends StatelessWidget {
  const _ResumeSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value);

  final String label;
  final String? value;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final visible =
        items.where((item) => item.value?.trim().isNotEmpty == true).toList();
    if (visible.isEmpty) {
      return Text(
        'Add profile details in Athlete Passport.',
        style: TextStyle(
          color: AppColors.textDark.withValues(alpha: 0.75),
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      children: [
        for (final item in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.value!.trim(),
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

enum _LinkKind { web, email, phone }

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.kind,
  });

  final IconData icon;
  final String label;
  final String? value;
  final _LinkKind kind;

  @override
  Widget build(BuildContext context) {
    final raw = value?.trim();
    final hasValue = raw != null && raw.isNotEmpty;
    final uri = hasValue ? _uriFor(raw, kind) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: uri == null
            ? null
            : () async {
                final opened = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open $label.')),
                  );
                }
              },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: hasValue
                ? AppColors.surfaceLight
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasValue
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: hasValue ? AppColors.primaryDeep : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textDark.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      hasValue ? raw : 'Add in Athlete Passport',
                      style: TextStyle(
                        color: hasValue
                            ? AppColors.primaryDeep
                            : AppColors.textDark.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w800,
                        decoration:
                            hasValue ? TextDecoration.underline : null,
                        decorationColor: AppColors.primaryDeep,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasValue)
                const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: AppColors.primaryDeep,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Uri? _uriFor(String raw, _LinkKind kind) {
    switch (kind) {
      case _LinkKind.email:
        return Uri(scheme: 'mailto', path: raw);
      case _LinkKind.phone:
        final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
        if (digits.isEmpty) return null;
        return Uri(scheme: 'tel', path: digits);
      case _LinkKind.web:
        final withScheme =
            raw.startsWith('http://') || raw.startsWith('https://')
                ? raw
                : 'https://$raw';
        return Uri.tryParse(withScheme);
    }
  }
}
