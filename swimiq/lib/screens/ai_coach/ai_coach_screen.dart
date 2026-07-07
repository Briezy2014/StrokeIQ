import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/ai_coach_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';
import '../video_lab/video_lab_screen.dart';

/// Corrective coaching — what to try fixing based on your latest video analysis.
class AiCoachScreen extends ConsumerWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
      ),
      body: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
          final brief = AiCoachService.build(data: data, swimmer: swimmer);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const _RoleBanner(
                emoji: '🤖',
                title: 'AI Coach',
                body:
                    'Short, actionable corrections from your video. Tells you what '
                    'to try in practice — not the full technical breakdown.',
                accent: AppColors.primary,
              ),
              const SizedBox(height: 16),
              SwimIqScreenHeader(
                title: brief.headline,
                subtitle: brief.summary,
              ),
              if (brief.sourceVideoTitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Based on: ${brief.sourceVideoTitle}'
                  '${brief.sourceEvent != null ? ' · ${brief.sourceEvent}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Corrections to try',
                icon: Icons.build_circle_outlined,
                lines: brief.correctionsToTry,
                emptyMessage: 'Run Video Lab analysis to unlock coaching priorities.',
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Practice focus',
                icon: Icons.fitness_center_outlined,
                lines: brief.practiceFocus,
                emptyMessage: 'Add goals or video notes for drill suggestions.',
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Keep doing',
                icon: Icons.thumb_up_outlined,
                lines: brief.keepDoing,
                emptyMessage: 'Log sessions to track what is working.',
              ),
              if (brief.analysisEngine != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Source engine: ${brief.analysisEngine}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
              const SizedBox(height: 20),
              if (!brief.hasVideoAnalysis)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VideoLabScreen()),
                    );
                  },
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Run full analysis in Video Lab'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VideoLabScreen()),
                    );
                  },
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('See full Video Lab breakdown'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RoleBanner extends StatelessWidget {
  const _RoleBanner({
    required this.emoji,
    required this.title,
    required this.body,
    required this.accent,
  });

  final String emoji;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                ),
                const SizedBox(height: 6),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.lines,
    required this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final List<String> lines;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (lines.isEmpty)
              Text(emptyMessage)
            else
              ...lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(line)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
