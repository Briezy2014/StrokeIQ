import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/recruiting/recruiting_resume_builder.dart';
import '../../core/recruiting/recruiting_resume_pdf.dart';
import '../../data/models/personal_best_entry.dart';
import '../../data/models/swimmer_profile.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_page_hero.dart';

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
  List<String> _championshipTags = const [];

  @override
  Widget build(BuildContext context) {
    return SubscriptionGatedScreen(
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
          final resume = RecruitingResumeBuilder.buildText(
            profile: data.profile,
            displayName: data.displayName(swimmer),
            personalBests: data.personalBests,
            swimIqScore: snapshot.swimIqScore,
            highestCut: snapshot.highestCut,
            championshipsQualified: tags,
          );

          _resumeText = resume;
          _profile = data.profile;
          _displayName = data.displayName(swimmer);
          _personalBests = data.personalBests;
          _swimIqScore = snapshot.swimIqScore;
          _highestCut = snapshot.highestCut;
          _championshipTags = tags;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const SwimIqPageHero(
                title: 'Best Times Résumé',
                subtitle: 'Clean one-page recruiting résumé — export as PDF for coaches.',
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    resume,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.45,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyResume(context),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
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
                'PDF includes top times, academics, honors, and performance snapshot. '
                'Power Index joins here as an Elite feature.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
            ],
          );
        },
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
