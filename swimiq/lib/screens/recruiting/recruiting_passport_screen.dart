import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/recruiting_passport_service.dart';
import '../../widgets/passport_module_ui.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

class RecruitingPassportScreen extends ConsumerWidget {
  const RecruitingPassportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recruiting Passport')),
      body: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
          final brief = RecruitingPassportService.build(
            data: data,
            swimmer: swimmer,
          );

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const PassportModuleBanner(
                emoji: '🎓',
                title: 'Recruiting Center',
                body:
                    'Shareable athlete card for college coaches — PBs, cuts, '
                    'academics, and contact info in one copy-paste block.',
                accent: Color(0xFF0B5CAD),
              ),
              const SizedBox(height: 16),
              SwimIqScreenHeader(
                title: brief.headline,
                subtitle: brief.academicLine,
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFFF8FCFF),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    brief.shareableCard,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: brief.shareableCard),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recruiting card copied to clipboard.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy recruiting card'),
              ),
              const SizedBox(height: 20),
              PassportModuleSection(
                title: 'Highlights',
                icon: Icons.star_outline,
                lines: brief.highlights,
              ),
              PassportModuleSection(
                title: 'Personal bests',
                icon: Icons.emoji_events_outlined,
                lines: brief.personalBests,
              ),
              PassportModuleSection(
                title: 'Verification',
                icon: Icons.verified_outlined,
                lines: [brief.contactLine],
              ),
            ],
          );
        },
      ),
    );
  }
}
