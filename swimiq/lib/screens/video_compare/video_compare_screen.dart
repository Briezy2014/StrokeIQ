import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/video_compare_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/passport_module_ui.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';
import '../video_lab/video_lab_screen.dart';

class VideoCompareScreen extends ConsumerWidget {
  const VideoCompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Compare')),
      body: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
          final brief = VideoCompareService.build(data: data, swimmer: swimmer);
          final dateFormat = DateFormat.yMMMd();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const PassportModuleBanner(
                emoji: '🎬',
                title: 'Video Compare',
                body:
                    'Side-by-side look at your two latest Video Lab analyses — '
                    'scores, priorities, and what changed.',
                accent: AppColors.primary,
              ),
              const SizedBox(height: 16),
              SwimIqScreenHeader(
                title: brief.headline,
                subtitle: brief.summary,
              ),
              if (brief.scoreDelta != null) ...[
                const SizedBox(height: 12),
                Chip(
                  label: Text(
                    brief.scoreDelta! >= 0
                        ? '+${brief.scoreDelta} overall score'
                        : '${brief.scoreDelta} overall score',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (brief.newer != null && brief.older != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _CompareCard(
                        label: 'Newer',
                        side: brief.newer!,
                        dateFormat: dateFormat,
                        accent: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompareCard(
                        label: 'Previous',
                        side: brief.older!,
                        dateFormat: dateFormat,
                        accent: Colors.grey.shade700,
                      ),
                    ),
                  ],
                )
              else if (brief.newer != null)
                _CompareCard(
                  label: 'Latest',
                  side: brief.newer!,
                  dateFormat: dateFormat,
                  accent: AppColors.primary,
                ),
              const SizedBox(height: 16),
              PassportModuleSection(
                title: 'Insights',
                icon: Icons.insights_outlined,
                lines: brief.insights,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VideoLabScreen()),
                  );
                },
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Open Video Lab'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.label,
    required this.side,
    required this.dateFormat,
    required this.accent,
  });

  final String label;
  final VideoCompareSide side;
  final DateFormat dateFormat;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              side.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(side.event, style: Theme.of(context).textTheme.bodySmall),
            if (side.analyzedAt != null)
              Text(
                dateFormat.format(side.analyzedAt!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 10),
            Text('Overall ${side.overallScore}/100'),
            Text('Technique ${side.techniqueScore} · Pace ${side.paceScore}'),
            if (side.priorities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Priorities',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              ...side.priorities.take(3).map((p) => Text('• $p')),
            ],
          ],
        ),
      ),
    );
  }
}
