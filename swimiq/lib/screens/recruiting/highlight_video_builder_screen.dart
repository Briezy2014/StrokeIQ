import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/swim_video.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swim_iq_feature_scaffold.dart';
import '../../widgets/swimmer_screen.dart';

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

  String _videoKey(SwimVideo video) {
    final id = video.id?.trim();
    if (id != null && id.isNotEmpty) return id;
    return video.displayTitle;
  }

  @override
  Widget build(BuildContext context) {
    return SwimIqFeatureScaffold(
      title: 'Highlight Video Builder',
      body: SubscriptionGatedScreen(
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
            final taggedCount = _tagsByVideoId.values
                .where((tags) => tags.isNotEmpty)
                .length;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const _HighlightHeader(),
                const SizedBox(height: 16),
                if (videos.isEmpty)
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Upload race videos in Video Lab first, then return here '
                        'to tag starts, turns, and finishes for your reel.',
                        style: TextStyle(
                          color: AppColors.textDark.withValues(alpha: 0.85),
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  ...videos.map((video) {
                    final key = _videoKey(video);
                    return _VideoTagCard(
                      video: video,
                      selectedTags: _tagsByVideoId[key] ?? const {},
                      onTagToggle: (tag, selected) {
                        setState(() {
                          final tags = _tagsByVideoId.putIfAbsent(
                            key,
                            () => <String>{},
                          );
                          if (selected) {
                            tags.add(tag);
                          } else {
                            tags.remove(tag);
                          }
                        });
                      },
                    );
                  }),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _buildReelPlan(context, videos),
                  icon: const Icon(Icons.movie_creation_outlined),
                  label: const Text('Preview highlight reel plan'),
                ),
                const SizedBox(height: 10),
                Text(
                  taggedCount == 0
                      ? 'Tap tags on a video above, then preview your reel plan.'
                      : '$taggedCount video${taggedCount == 1 ? '' : 's'} tagged for this session. '
                          'Automatic reel stitching ships in a future update.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.78),
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

  void _buildReelPlan(BuildContext context, List<SwimVideo> videos) {
    final titleByKey = <String, String>{
      for (final video in videos) _videoKey(video): video.displayTitle,
    };

    final tagged = _tagsByVideoId.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    if (tagged.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Tag a clip first'),
          content: const Text(
            'Tap one or more tags on a video card (Race, Best start, '
            'Best turn, etc.), then press Preview again.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }

    final lines = <String>[];
    var step = 1;
    for (final entry in tagged) {
      final title = titleByKey[entry.key] ?? entry.key;
      lines.add('$step. $title — ${entry.value.join(', ')}');
      step += 1;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Highlight reel plan',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDeep,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Suggested recruiting reel order',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                for (final line in lines) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Open Video Lab to export clips. Automatic reel generation '
                  'is coming in a future Elite update.',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.7),
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HighlightHeader extends StatelessWidget {
  const _HighlightHeader();

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
            'Highlight Video Builder',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tag your best moments — SwimIQ helps assemble a recruiting highlight reel.',
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
      color: Colors.white,
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
                    color: AppColors.textDark,
                  ),
            ),
            if (video.eventLabel.isNotEmpty)
              Text(
                video.eventLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textDark.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
              ),
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
