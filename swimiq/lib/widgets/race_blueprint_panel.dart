import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/coaching/race_blueprint.dart';
import '../core/theme/app_theme.dart';
import '../data/models/video_engine_v2/analysis_results.dart';

/// Race Blueprint: performance energy curve + phase cues, optionally synced to video.
class RaceBlueprintPanel extends StatefulWidget {
  const RaceBlueprintPanel({
    super.key,
    required this.results,
    required this.stroke,
    required this.recommendations,
    this.videoUrl,
  });

  final AnalysisResults results;
  final String stroke;
  final List<String> recommendations;
  final String? videoUrl;

  @override
  State<RaceBlueprintPanel> createState() => _RaceBlueprintPanelState();
}

class _RaceBlueprintPanelState extends State<RaceBlueprintPanel> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _videoFailed = false;
  String? _activePhaseId;
  double _playhead = 0;

  @override
  void initState() {
    super.initState();
    _bootstrapVideo(widget.videoUrl);
  }

  @override
  void didUpdateWidget(covariant RaceBlueprintPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _bootstrapVideo(widget.videoUrl);
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    _videoReady = false;
    if (c != null) {
      c.removeListener(_onVideoTick);
      c.dispose();
    }
  }

  Future<void> _bootstrapVideo(String? url) async {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      if (mounted) {
        setState(() {
          _videoFailed = false;
          _videoReady = false;
        });
      }
      return;
    }
    final controller = VideoPlayerController.networkUrl(Uri.parse(trimmed));
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onVideoTick);
      setState(() {
        _videoReady = true;
        _videoFailed = false;
      });
    } catch (_) {
      await controller.dispose();
      if (_controller == controller) _controller = null;
      if (mounted) {
        setState(() {
          _videoReady = false;
          _videoFailed = true;
        });
      }
    }
  }

  void _onVideoTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized || !mounted) return;
    final duration = c.value.duration.inMilliseconds;
    if (duration <= 0) return;
    final fraction = (c.value.position.inMilliseconds / duration).clamp(0.0, 1.0);
    final blueprint = _blueprint;
    String? activeId;
    for (final phase in blueprint.phases) {
      if (fraction >= phase.startFraction && fraction <= phase.endFraction) {
        activeId = phase.id;
        break;
      }
    }
    if ((fraction - _playhead).abs() > 0.004 || activeId != _activePhaseId) {
      setState(() {
        _playhead = fraction;
        _activePhaseId = activeId;
      });
    }
  }

  RaceBlueprint get _blueprint => RaceBlueprintBuilder.fromResults(
        results: widget.results,
        stroke: widget.stroke,
        recommendations: widget.recommendations,
      );

  Future<void> _seekToPhase(RaceBlueprintPhase phase) async {
    final c = _controller;
    setState(() => _activePhaseId = phase.id);
    if (c == null || !c.value.isInitialized) return;
    final duration = c.value.duration.inMilliseconds;
    if (duration <= 0) return;
    final ms = phase.seekMs ??
        (phase.midFraction * duration).round();
    final clamped = ms.clamp(0, duration);
    await c.seekTo(Duration(milliseconds: clamped));
    if (!c.value.isPlaying) {
      await c.play();
    }
    if (mounted) {
      setState(() => _playhead = clamped / duration);
    }
  }

  Future<void> _togglePlay() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final blueprint = _blueprint;
    final spots = [
      for (final p in blueprint.energyPoints) FlSpot(p.x, p.y),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Race Blueprint',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Performance energy curve · start → wall',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            blueprint.caption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark.withValues(alpha: 0.72),
                ),
          ),
          if (widget.videoUrl != null) ...[
            const SizedBox(height: 12),
            _VideoStrip(
              controller: _controller,
              ready: _videoReady,
              failed: _videoFailed,
              onTogglePlay: _togglePlay,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 168,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 1,
                minY: 0,
                maxY: 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    if (_videoReady)
                      VerticalLine(
                        x: _playhead,
                        color: AppColors.accent,
                        strokeWidth: 2,
                        dashArray: const [4, 3],
                      ),
                    for (final phase in blueprint.phases.skip(1))
                      VerticalLine(
                        x: phase.startFraction,
                        color: AppColors.primary.withValues(alpha: 0.16),
                        strokeWidth: 1,
                      ),
                  ],
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 0.5,
                      getTitlesWidget: (value, meta) {
                        String label;
                        if (value >= 0.9) {
                          label = 'High';
                        } else if (value <= 0.1) {
                          label = 'Low';
                        } else if ((value - 0.5).abs() < 0.05) {
                          label = 'Effort';
                        } else {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark.withValues(alpha: 0.55),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 0.25,
                      getTitlesWidget: (value, meta) {
                        final labels = <double, String>{
                          0.0: 'Start',
                          0.25: 'Breakout',
                          0.5: 'Mid',
                          0.75: 'Finish',
                          1.0: 'Wall',
                        };
                        String? label;
                        for (final entry in labels.entries) {
                          if ((value - entry.key).abs() < 0.02) {
                            label = entry.value;
                            break;
                          }
                        }
                        if (label == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primaryDeep,
                    barWidth: 3.2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.28),
                          AppColors.primary.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchCallback: (event, response) {
                    // Seek only on release so drag scrubbing does not spam seeks.
                    final isRelease =
                        event is FlTapUpEvent || event is FlPanEndEvent;
                    if (!isRelease) return;
                    final touched = response?.lineBarSpots;
                    if (touched == null || touched.isEmpty) return;
                    final x = touched.first.x;
                    RaceBlueprintPhase? hit;
                    for (final phase in blueprint.phases) {
                      if (x >= phase.startFraction && x <= phase.endFraction) {
                        hit = phase;
                        break;
                      }
                    }
                    if (hit != null) {
                      _seekToPhase(hit);
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            'Effort ${(s.y * 100).round()}%',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            blueprint.footer,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;
              final tiles = [
                for (final phase in blueprint.phases)
                  _PhaseChip(
                    phase: phase,
                    selected: _activePhaseId == phase.id,
                    canSeek: _videoReady,
                    onTap: () => _seekToPhase(phase),
                  ),
              ];
              if (wide) {
                return Row(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: tiles[i]),
                    ],
                  ],
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tiles
                    .map(
                      (t) => SizedBox(
                        width: (constraints.maxWidth - 8) / 2,
                        child: t,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (blueprint.usesMeasuredTiming) ...[
            const SizedBox(height: 8),
            Text(
              'Timed phases from this clip are marked on the curve.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VideoStrip extends StatelessWidget {
  const _VideoStrip({
    required this.controller,
    required this.ready,
    required this.failed,
    required this.onTogglePlay,
  });

  final VideoPlayerController? controller;
  final bool ready;
  final bool failed;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Video preview unavailable — the blueprint still shows your race map.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      );
    }
    if (!ready || controller == null || !controller!.value.isInitialized) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }

    final c = controller!;
    final playing = c.value.isPlaying;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: const Color(0xFF041526),
              child: VideoPlayer(c),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onTogglePlay,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Text(
                'Synced to blueprint',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({
    required this.phase,
    required this.selected,
    required this.canSeek,
    required this.onTap,
  });

  final RaceBlueprintPhase phase;
  final bool selected;
  final bool canSeek;
  final VoidCallback onTap;

  IconData get _icon {
    switch (phase.id) {
      case 'start_uw':
        return Icons.waves;
      case 'breakout':
        return Icons.trending_up;
      case 'mid':
        return Icons.timeline;
      case 'finish':
        return Icons.flag;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryDeep.withValues(alpha: 0.12)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primaryDeep
                  : AppColors.primary.withValues(alpha: 0.18),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _icon,
                    size: 16,
                    color: selected
                        ? AppColors.primaryDeep
                        : AppColors.primaryDeep.withValues(alpha: 0.85),
                  ),
                  const Spacer(),
                  if (canSeek)
                    Icon(
                      Icons.play_circle_outline,
                      size: 16,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    )
                  else if (phase.measured)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TIMED',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                phase.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                phase.cue,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.25,
                  color: AppColors.textDark.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
