import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/swim_dna_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/passport_module_ui.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

class SwimDnaScreen extends ConsumerWidget {
  const SwimDnaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('SwimDNA™')),
      body: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
          final brief = SwimDnaService.build(data: data, swimmer: swimmer);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const PassportModuleBanner(
                emoji: '🧬',
                title: 'SwimDNA™',
                body:
                    'Your stroke fingerprint from PBs, training mix, and video '
                    'trends — how SwimIQ sees your racing identity.',
                accent: AppColors.primary,
              ),
              const SizedBox(height: 16),
              SwimIqScreenHeader(
                title: brief.headline,
                subtitle: brief.summary,
              ),
              const SizedBox(height: 16),
              Text(
                brief.raceProfile,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(brief.videoTrend),
              const SizedBox(height: 16),
              ...brief.traits.map(
                (trait) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      trait.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(trait.detail),
                    trailing: _StrengthRing(value: trait.strength),
                  ),
                ),
              ),
              PassportModuleSection(
                title: 'Stroke mix',
                icon: Icons.pie_chart_outline,
                lines: brief.strokeMix,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StrengthRing extends StatelessWidget {
  const _StrengthRing({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value / 100,
            strokeWidth: 4,
            color: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          ),
          Text(
            '$value',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
