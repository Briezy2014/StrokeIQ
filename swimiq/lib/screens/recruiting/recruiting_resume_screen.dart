import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/recruiting/recruiting_resume_builder.dart';
import 'recruiting_resume_io.dart'
    if (dart.library.html) 'recruiting_resume_stub.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_page_hero.dart';

/// Pro-tier one-page recruiting résumé with export.
class RecruitingResumeScreen extends ConsumerStatefulWidget {
  const RecruitingResumeScreen({super.key});

  @override
  ConsumerState<RecruitingResumeScreen> createState() =>
      _RecruitingResumeScreenState();
}

class _RecruitingResumeScreenState extends ConsumerState<RecruitingResumeScreen> {
  String? _resumeText;

  @override
  Widget build(BuildContext context) {
    return SubscriptionGatedScreen(
      minimumTier: SubscriptionTier.pro,
      title: 'Unlock SwimIQ Pro',
      message: 'Best Times Résumé is included with Pro.',
      teaserFeatures: const [
        'Auto-generated recruiting résumé',
        'Top times, honors & academics',
        'Export for college coaches',
      ],
      child: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
          final snapshot = data.passportSnapshot(swimmer);
          final resume = RecruitingResumeBuilder.buildText(
            profile: data.profile,
            displayName: data.displayName(swimmer),
            personalBests: data.personalBests,
            swimIqScore: snapshot.swimIqScore,
            highestCut: snapshot.highestCut,
            championshipsQualified: RecruitingResumeBuilder.championshipTags(
              highestCut: snapshot.highestCut,
              personalBests: data.personalBests,
            ),
          );
          _resumeText = resume;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const SwimIqPageHero(
                title: 'Best Times Résumé',
                subtitle: 'Clean one-page recruiting résumé — ready to share with coaches.',
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
                      onPressed: () => _exportResume(context, swimmer),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Export PDF'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Power Index will appear here as an Elite feature. '
                'Export saves a formatted text résumé coaches can open anywhere.',
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

  Future<void> _exportResume(BuildContext context, String swimmer) async {
    final text = _resumeText;
    if (text == null) return;

    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Résumé copied — paste into Google Docs or Word and Save as PDF.',
          ),
        ),
      );
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeName = swimmer.replaceAll(RegExp(r'[^\w\-]'), '_');
      final fileName = 'SwimIQ_Resume_$safeName.txt';
      // ignore: avoid_slow_async_io
      await _writeResumeFile('${dir.path}/$fileName', text);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Résumé saved to ${dir.path}/$fileName (also copied).'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Résumé copied. Could not save file: $e')),
      );
    }
  }

  Future<void> _writeResumeFile(String path, String text) async {
    // Deferred to keep web builds free of dart:io.
    return recruitingResumeFileWriter(path, text);
  }
}
