import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/env.dart';
import '../../core/models/subscription_plan.dart';
import '../../core/recruiting/highlight_reel_planner.dart';
import '../../core/services/video_engine_v2_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/swim_video.dart';
import '../../providers/app_providers.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swim_iq_feature_scaffold.dart';
import '../../widgets/swimmer_screen.dart';

/// Pro-tier highlight reel organizer — tags moments, then Elite builds
/// a clip pack + auto-stitched recruiting MP4.
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
  bool _building = false;
  HighlightReelResult? _lastReel;

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
          'Auto-build a shareable recruiting reel',
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
                  onPressed: _building || taggedCount == 0
                      ? null
                      : () => _generateReel(context, videos, swimmer),
                  icon: _building
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _building
                        ? 'Building recruiting reel…'
                        : 'Build recruiting reel',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: taggedCount == 0
                      ? null
                      : () => _previewPlan(context, videos),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Preview reel plan'),
                ),
                const SizedBox(height: 10),
                Text(
                  taggedCount == 0
                      ? 'Tap tags on a video above, then build your recruiting reel.'
                      : '$taggedCount video${taggedCount == 1 ? '' : 's'} tagged — '
                          'Elite will cut a clip pack and stitch one shareable MP4.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
                if (_lastReel != null) ...[
                  const SizedBox(height: 16),
                  _ReelReadyCard(
                    reel: _lastReel!,
                    onOpenReel: () => _openUrl(_lastReel!.reelUrl),
                    onOpenClip: _openUrl,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _generateReel(
    BuildContext context,
    List<SwimVideo> videos,
    String swimmer,
  ) async {
    final segments = HighlightReelPlanner.buildSegments(
      tagsByVideoId: _tagsByVideoId,
      videos: videos,
    );
    if (segments.isEmpty) {
      _showMessage(
        title: 'Tag a clip first',
        body:
            'Tap one or more tags on a video card, then build again. '
            'Videos need a Video Lab upload path.',
      );
      return;
    }

    setState(() => _building = true);
    try {
      if (Env.isPublicHostedWeb) {
        throw VideoEngineV2Exception(
          'Automatic highlight video stitching is coming to the website soon. '
          'For now, use tagged clips in your recruiting résumé export.',
          errorCode: 'SERVER_UNAVAILABLE',
          retriable: false,
        );
      }
      final health = await ref.read(videoEngineV2ServiceProvider).checkHealth();
      if (!health.reachable || !health.mediaToolsReady) {
        throw VideoEngineV2Exception(
          health.reachable
              ? 'Highlight stitching tools are not ready on this computer yet.'
              : 'Highlight video builder is temporarily unavailable. Try again later.',
          errorCode: 'SERVER_UNAVAILABLE',
          retriable: true,
        );
      }

      final result =
          await ref.read(videoEngineV2ServiceProvider).createHighlightReel(
                segments: segments.map((s) => s.toJson()).toList(),
                title: '$swimmer Recruiting Reel',
              );
      if (!mounted) return;
      setState(() => _lastReel = result);
      _showReelSheet(result);
    } on VideoEngineV2Exception catch (e) {
      if (!mounted) return;
      _showMessage(title: 'Reel not ready', body: e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        title: 'Reel not ready',
        body:
            'Could not build the highlight reel right now. '
            'Please try again later.',
      );
    } finally {
      if (mounted) setState(() => _building = false);
    }
  }

  void _previewPlan(BuildContext context, List<SwimVideo> videos) {
    final segments = HighlightReelPlanner.buildSegments(
      tagsByVideoId: _tagsByVideoId,
      videos: videos,
    );
    if (segments.isEmpty) {
      _showMessage(
        title: 'Tag a clip first',
        body: 'Tap tags on a video card, then preview again.',
      );
      return;
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
                for (var i = 0; i < segments.length; i++) ...[
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
                      '${i + 1}. ${segments[i].label} — ${segments[i].tag}',
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
                  'Tap Build recruiting reel to cut clips and stitch one shareable MP4.',
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

  void _showReelSheet(HighlightReelResult reel) {
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
                  'Recruiting reel ready',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDeep,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  reel.message,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _openUrl(reel.reelUrl),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Open full highlight reel'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Clip pack (${reel.clips.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                for (final clip in reel.clips)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${clip.tag} — ${clip.label}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${((clip.endMs - clip.startMs) / 1000.0).toStringAsFixed(1)}s clip',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download_outlined),
                      onPressed: () => _openUrl(clip.downloadUrl),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _showMessage(
        title: 'Could not open link',
        body: 'Copy this URL into Chrome:\n$url',
      );
    }
  }

  void _showMessage({
    required String title,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
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
            'Tag your best moments — SwimIQ cuts a clip pack and stitches one shareable recruiting reel.',
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

class _ReelReadyCard extends StatelessWidget {
  const _ReelReadyCard({
    required this.reel,
    required this.onOpenReel,
    required this.onOpenClip,
  });

  final HighlightReelResult reel;
  final VoidCallback onOpenReel;
  final Future<void> Function(String url) onOpenClip;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest recruiting reel',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${reel.clips.length} clips stitched · tap to download',
              style: TextStyle(
                color: AppColors.textDark.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onOpenReel,
              icon: const Icon(Icons.movie_creation_outlined),
              label: const Text('Open full reel'),
            ),
            const SizedBox(height: 8),
            for (final clip in reel.clips.take(4))
              TextButton(
                onPressed: () => onOpenClip(clip.downloadUrl),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${clip.tag} — ${clip.label}'),
                ),
              ),
          ],
        ),
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
