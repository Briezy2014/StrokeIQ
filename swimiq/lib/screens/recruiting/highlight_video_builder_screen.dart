import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subscription_plan.dart';
import '../../data/models/swim_video.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_page_hero.dart';

/// Pro-tier highlight reel organizer (tag races, starts, turns, finishes).
class HighlightVideoBuilderScreen extends ConsumerStatefulWidget {
  const HighlightVideoBuilderScreen({super.key});

  static const tagOptions = [
    'Race',
    'Best start',
    'Best turn',
    'Best finish',
    'Underwaters',
    'Sprint finish',
  ];

  @override
  ConsumerState<HighlightVideoBuilderScreen> createState() =>
      _HighlightVideoBuilderScreenState();
}

class _HighlightVideoBuilderScreenState
    extends ConsumerState<HighlightVideoBuilderScreen> {
  final Map<String, Set<String>> _tagsByVideoId = {};

  @override
  Widget build(BuildContext context) {
    return SubscriptionGatedScreen(
      minimumTier: SubscriptionTier.pro,
      title: 'Unlock SwimIQ Pro',
      message: 'Highlight Video Builder is included with Pro.',
      teaserFeatures: const [
        'Tag race videos for recruiting',
        'Mark best starts, turns & finishes',
        'Build a highlight reel plan',
      ],
      child: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
          final videos = data.userFacingVideos;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const SwimIqPageHero(
                title: 'Highlight Video Builder',
                subtitle: 'Tag your best moments — SwimIQ will help assemble a '
                    'recruiting highlight reel.',
              ),
              const SizedBox(height: 16),
              if (videos.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Upload race videos in Video Lab first, then return here '
                      'to tag starts, turns, and finishes for your reel.',
                    ),
                  ),
                )
              else
                ...videos.map((video) => _VideoTagCard(
                      video: video,
                      selectedTags: _tagsByVideoId[video.id ?? ''] ?? {},
                      onTagToggle: (tag, selected) {
                        setState(() {
                          final id = video.id ?? video.displayTitle;
                          final tags = _tagsByVideoId.putIfAbsent(
                            id,
                            () => <String>{},
                          );
                          if (selected) {
                            tags.add(tag);
                          } else {
                            tags.remove(tag);
                          }
                        });
                      },
                    )),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: videos.isEmpty ? null : () => _buildReelPlan(context),
                icon: const Icon(Icons.movie_creation_outlined),
                label: const Text('Preview highlight reel plan'),
              ),
              const SizedBox(height: 8),
              Text(
                'Automatic reel stitching ships in a future update. Tags are '
                'saved for this session — sync to cloud coming soon.',
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

  void _buildReelPlan(BuildContext context) {
    final tagged = _tagsByVideoId.entries
        .where((e) => e.value.isNotEmpty)
        .toList();
    if (tagged.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag at least one video clip first.')),
      );
      return;
    }

    final lines = <String>[];
    for (final entry in tagged) {
      lines.add('${entry.key}: ${entry.value.join(', ')}');
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Highlight reel plan'),
        content: SingleChildScrollView(
          child: Text(
            'Suggested recruiting reel order:\n\n${lines.join('\n')}\n\n'
            'Open Video Lab to export clips, or wait for automatic reel '
            'generation in an upcoming Elite update.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _VideoTagCard extends StatelessWidget {
  const _VideoTagCard({
    required this.video,
    required this.selectedTags,
    required this.onTagToggle,
  });

  final SwimVideo video;
  final Set<String> selectedTags;
  final void Function(String tag, bool selected) onTagToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              video.displayTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            if (video.eventLabel.isNotEmpty)
              Text(video.eventLabel, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in HighlightVideoBuilderScreen.tagOptions)
                  FilterChip(
                    label: Text(tag),
                    selected: selectedTags.contains(tag),
                    onSelected: (value) => onTagToggle(tag, value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
