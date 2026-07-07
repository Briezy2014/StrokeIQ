import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/wellness_readiness_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/passport_module_ui.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

class WellnessReadinessScreen extends ConsumerWidget {
  const WellnessReadinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wellness & Readiness')),
      body: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
          final brief = WellnessReadinessService.build(
            data: data,
            swimmer: swimmer,
          );

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const PassportModuleBanner(
                emoji: '💚',
                title: 'Wellness & Readiness',
                body:
                    'Daily check-in from Passport (sleep, soreness, illness) '
                    'combined with training load — not medical advice.',
                accent: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 16),
              SwimIqScreenHeader(
                title: brief.headline,
                subtitle: brief.summary,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '${brief.readinessScore}',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: _scoreColor(brief.readinessScore),
                            ),
                      ),
                      Text(
                        brief.readinessLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (brief.sleepHours != null)
                    Chip(label: Text('Sleep: ${brief.sleepHours}h')),
                  if (brief.sorenessLevel != null)
                    Chip(label: Text('Soreness: ${brief.sorenessLevel}')),
                  if (brief.illnessNotes != null)
                    Chip(label: Text('Note: ${brief.illnessNotes}')),
                ],
              ),
              const SizedBox(height: 16),
              PassportModuleSection(
                title: 'Factors',
                icon: Icons.fact_check_outlined,
                lines: brief.factors,
              ),
              PassportModuleSection(
                title: 'Recommendations',
                icon: Icons.lightbulb_outline,
                lines: brief.recommendations,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(homeTabIndexProvider.notifier).state = HomeTab.passport;
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.edit_note),
                label: const Text('Update wellness in Passport'),
              ),
            ],
          );
        },
      ),
    );
  }

  static Color _scoreColor(int score) {
    if (score >= 85) return const Color(0xFF2E7D32);
    if (score >= 65) return const Color(0xFFF9A825);
    if (score >= 45) return const Color(0xFFEF6C00);
    return const Color(0xFFC62828);
  }
}
