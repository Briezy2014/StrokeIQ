import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/video_analytics_service.dart';
import '../../../core/services/video_engine_v2_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/video_engine_v2/video_engine_v2_models.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/swimiq_ui.dart';
import 'components/limitations_panel.dart';
import 'components/metric_tile.dart';
import 'video_job_progress_screen.dart';

/// Results viewer for Video Engine V2 jobs.
class VideoAnalysisResultsScreen extends ConsumerStatefulWidget {
  const VideoAnalysisResultsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<VideoAnalysisResultsScreen> createState() =>
      _VideoAnalysisResultsScreenState();
}

class _VideoAnalysisResultsScreenState
    extends ConsumerState<VideoAnalysisResultsScreen> {
  AnalysisResults? _results;
  Object? _error;
  bool _loading = true;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results =
          await ref.read(videoEngineV2ServiceProvider).getResults(widget.jobId);
      if (results.reportFailed) {
        ref.read(videoAnalyticsServiceProvider).logEvent(
          VideoAnalyticsService.reportUnavailable,
          {'job_id': widget.jobId, 'status': results.status},
        );
      }
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await ref.read(videoEngineV2ServiceProvider).retryJob(widget.jobId);
      ref.read(videoAnalyticsServiceProvider).logEvent(
        VideoAnalyticsService.analysisRetry,
        {'job_id': widget.jobId},
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => VideoJobProgressScreen(jobId: widget.jobId),
        ),
      );
    } on VideoEngineV2Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  List<AnalysisMetric> _metricsMatching(AnalysisResults r, List<String> keys) {
    return r.metrics.where((m) {
      final hay = '${m.name} ${m.displayName}'.toLowerCase();
      return keys.any(hay.contains);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis results'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      final message = _error is VideoEngineV2Exception
          ? (_error as VideoEngineV2Exception).message
          : _error.toString();
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SwimIqScreenHeader(
            title: 'Could not load results',
            subtitle: 'Check your connection or try again.',
          ),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }

    final results = _results;
    if (results == null) {
      return const EmptyStateMessage(message: 'No analysis results yet.');
    }

    if (results.isFailed && !results.hasDeterministicMetrics) {
      final friendly = VideoEngineV2Service.userMessageForErrorCode(
        results.errorCode,
        fallback: results.errorMessage,
      );
      final notes = results.limitations
          .where((l) => !_SummaryTab._isInternalLimitation(l))
          .toList(growable: false);
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwimIqScreenHeader(
            title: 'Analysis needs another try',
            subtitle: friendly,
          ),
          const SizedBox(height: 16),
          if (notes.isNotEmpty) ...[
            LimitationsPanel(title: 'Notes', limitations: notes),
            const SizedBox(height: 16),
          ],
          if (results.isClipQualityFailure) ...[
            Text(
              'A new clip usually works better than retrying the same one. '
              'Film from the side, keep the full body in frame, and avoid heavy splash or shaking.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Back to Video Lab'),
            ),
          ] else
            FilledButton(
              onPressed: _retrying ? null : _retry,
              child: Text(_retrying ? 'Retrying…' : 'Retry analysis'),
            ),
        ],
      );
    }

    final startMetrics = _metricsMatching(results, [
      'start',
      'reaction',
      'underwater',
      'breakout',
      'kick',
    ]);
    final strokeMetrics = _metricsMatching(results, [
      'stroke',
      'tempo',
      'rate',
      'cycle',
      'distance_per',
      'dps',
    ]);
    final turnMetrics = _metricsMatching(results, [
      'turn',
      'finish',
      'wall',
    ]);
    final used = {...startMetrics, ...strokeMetrics, ...turnMetrics};
    final otherMetrics =
        results.metrics.where((m) => !used.contains(m)).toList();

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Material(
            color: AppColors.surfaceLight,
            child: const TabBar(
              isScrollable: true,
              labelColor: AppColors.primaryDark,
              tabs: [
                Tab(text: 'Summary'),
                Tab(text: 'Metrics'),
                Tab(text: 'Coaching'),
                Tab(text: 'Details'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SummaryTab(results: results, onRetry: _retry, retrying: _retrying),
                _MetricsTab(
                  results: results,
                  startMetrics: startMetrics,
                  strokeMetrics: strokeMetrics,
                  turnMetrics: turnMetrics,
                  otherMetrics: otherMetrics,
                ),
                _CoachingTab(results: results),
                _DetailsTab(results: results),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.results,
    required this.onRetry,
    required this.retrying,
  });

  final AnalysisResults results;
  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final report = results.report;
    final coachFacingNotes = results.limitations
        .where((l) => !_isInternalLimitation(l))
        .toList(growable: false);
    final hasCoachSummary = report?.summary?.trim().isNotEmpty == true;
    final hasStrengths = report?.strengths.isNotEmpty == true;
    final hasImprovements = report?.priorityImprovements.isNotEmpty == true;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwimIqScreenHeader(
          title: results.isFailed && !hasCoachSummary
              ? 'Analysis needs another try'
              : 'Your swim coaching report',
          subtitle: hasCoachSummary || hasStrengths || hasImprovements
              ? 'Strengths, improvements, drills, and next steps'
              : 'Open the Coaching tab for tips, or retry if the report is empty',
        ),
        const SizedBox(height: 12),
        if (hasCoachSummary) ...[
          Text(
            'Coach summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(report!.summary!),
          const SizedBox(height: 16),
        ],
        if (hasStrengths) ...[
          Text(
            'Strengths',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          ...report!.strengths.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $s'),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (hasImprovements) ...[
          Text(
            'What to fix next',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          ...report!.priorityImprovements.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• ${p.title}'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open the Coaching tab for drills and next-race cues.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
        ],
        if (report?.raceRecommendations.isNotEmpty == true) ...[
          Text(
            'Next race',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          ...report!.raceRecommendations.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $r'),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (!hasCoachSummary && results.reportFailed) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Text(
              VideoEngineV2Service.userMessageForErrorCode(
                _geminiFailureCodeFromResults(results) ??
                    'GEMINI_REPORT_UNAVAILABLE',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (coachFacingNotes.isNotEmpty) ...[
          LimitationsPanel(
            title: 'Notes',
            limitations: coachFacingNotes,
          ),
          const SizedBox(height: 16),
        ],
        if (results.isFailed && !results.isClipQualityFailure) ...[
          FilledButton(
            onPressed: retrying ? null : onRetry,
            child: Text(retrying ? 'Retrying…' : 'Retry analysis'),
          ),
        ],
      ],
    );
  }

  static bool _isInternalLimitation(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('pose dependency') ||
        lower.contains('missing=[') ||
        lower.contains('no module named') ||
        lower.contains('torch') ||
        lower.contains('mmpose') ||
        lower.contains('mmcv') ||
        lower.contains('mmengine') ||
        lower.contains('skipped_no_smoothed') ||
        lower.contains('supabase_persist') ||
        lower.contains('first 45') ||
        lower.contains('gemini_report_failed') ||
        lower.contains('local_coaching_fallback');
  }

}

String? _strokeLabel(AnalysisResults results) {
  final stroke = results.stroke;
  if (stroke == null || stroke.isEmpty) return null;
  final predicted = stroke['predicted'] ?? stroke['stroke'] ?? stroke['name'];
  if (predicted == null) return null;
  final text = predicted.toString().trim();
  if (text.isEmpty) return null;
  return text.replaceAll('_', ' ');
}

String? _geminiFailureCodeFromResults(AnalysisResults results) {
  for (final raw in results.limitations) {
    final lower = raw.toLowerCase();
    const prefix = 'gemini_report_failed:';
    if (!lower.startsWith(prefix)) continue;
    final code = raw.substring(prefix.length).trim();
    if (code.isNotEmpty) return code.toUpperCase();
  }
  return null;
}

class _MetricsTab extends StatelessWidget {
  const _MetricsTab({
    required this.results,
    required this.startMetrics,
    required this.strokeMetrics,
    required this.turnMetrics,
    required this.otherMetrics,
  });

  final AnalysisResults results;
  final List<AnalysisMetric> startMetrics;
  final List<AnalysisMetric> strokeMetrics;
  final List<AnalysisMetric> turnMetrics;
  final List<AnalysisMetric> otherMetrics;

  AnalysisMetric? _findMetric(List<String> nameBits) {
    for (final m in results.metrics) {
      final hay = '${m.name} ${m.displayName}'.toLowerCase();
      if (nameBits.every((b) => hay.contains(b))) return m;
    }
    return null;
  }

  String _clarityLabel(AnalysisMetric? coverage) {
    final v = coverage?.value?.toDouble();
    if (v == null) return 'Not measured';
    if (v >= 0.45) return 'Clear — good side view for coaching';
    if (v >= 0.25) return 'Okay — some splash or distance limited the view';
    return 'Limited — splash, underwater, or camera angle hid the body';
  }

  @override
  Widget build(BuildContext context) {
    final coverage = _findMetric(['coverage']) ?? _findMetric(['target_coverage']);
    final processed =
        _findMetric(['processed']) ?? _findMetric(['frames analyzed']);
    final detected = _findMetric(['detections']) ??
        _findMetric(['frames_with_detections']) ??
        _findMetric(['with swimmer']);
    final hasRaceMetrics = startMetrics.isNotEmpty ||
        strokeMetrics.isNotEmpty ||
        turnMetrics.isNotEmpty;

    Widget coachCard(String title, String value, String help) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: AppColors.primaryDark,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(help, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    Widget section(String title, List<AnalysisMetric> metrics) {
      if (metrics.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 8),
          ...metrics.map((m) => MetricTile(metric: m)),
          const SizedBox(height: 12),
        ],
      );
    }

    final processedN = processed?.value?.toInt();
    final detectedN = detected?.value?.toInt();
    String reviewed;
    if (processedN != null && detectedN != null && processedN > 0) {
      final pct = ((detectedN / processedN) * 100).clamp(0, 100).round();
      reviewed =
          'We reviewed about $processedN frames and found the swimmer in $pct% of them.';
    } else if (processedN != null) {
      reviewed = 'We reviewed about $processedN frames from this clip.';
    } else {
      reviewed = 'Frame counts were not available for this clip.';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'What this means for coaching',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
        ),
        const SizedBox(height: 8),
        coachCard(
          'VIDEO CLARITY',
          _clarityLabel(coverage),
          'Clearer side-view video = sharper stroke notes next time.',
        ),
        coachCard(
          'HOW MUCH WE REVIEWED',
          reviewed,
          'This is not a race split. It tells you how much of the clip Elite could use.',
        ),
        if (_strokeLabel(results) != null)
          coachCard(
            'STROKE',
            _strokeLabel(results)!,
            'Used to pick stroke-specific coaching cues.',
          ),
        if (hasRaceMetrics) ...[
          const SizedBox(height: 8),
          section('Starts / underwater', startMetrics),
          section('Stroke', strokeMetrics),
          section('Turns / finishes', turnMetrics),
        ],
        const SizedBox(height: 4),
        Text(
          'Open the Coaching tab for the pro, the con, dryland drills, and next-race cue.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _CoachingTab extends StatelessWidget {
  const _CoachingTab({required this.results});

  final AnalysisResults results;

  @override
  Widget build(BuildContext context) {
    final report = results.report;
    if (report == null || !report.isAvailable) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            VideoEngineV2Service.userMessageForErrorCode(
              _geminiFailureCodeFromResults(results) ??
                  'GEMINI_REPORT_UNAVAILABLE',
            ),
          ),
          if (results.hasDeterministicMetrics) ...[
            const SizedBox(height: 12),
            const Text(
              'Deterministic metrics are still available on the Metrics tab.',
            ),
          ],
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (report.summary?.trim().isNotEmpty == true) ...[
          Text('Coach snapshot', style: _h(context)),
          const SizedBox(height: 6),
          Text(report.summary!),
          const SizedBox(height: 16),
        ],
        if (report.strengths.isNotEmpty) ...[
          Text('Pro (keep this)', style: _h(context)),
          const SizedBox(height: 6),
          ...report.strengths.map((s) => _bullet(s)),
          const SizedBox(height: 16),
        ],
        if (report.priorityImprovements.isNotEmpty) ...[
          Text('Con + dryland drills', style: _h(context)),
          const SizedBox(height: 6),
          ...report.priorityImprovements.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  ...p.drills.map((d) => _bullet(d)),
                ],
              ),
            );
          }),
        ],
        if (report.raceRecommendations.isNotEmpty) ...[
          Text('Next race + time-drop estimate', style: _h(context)),
          const SizedBox(height: 6),
          ...report.raceRecommendations.map(_bullet),
          const SizedBox(height: 16),
        ],
        if (report.limitationsStatement?.trim().isNotEmpty == true) ...[
          Text('Notes', style: _h(context)),
          const SizedBox(height: 6),
          Text(report.limitationsStatement!),
        ],
      ],
    );
  }

  TextStyle? _h(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• '),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.results});

  final AnalysisResults results;

  static bool _isInternalLimitation(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('pose dependency') ||
        lower.contains('missing=[') ||
        lower.contains('no module named') ||
        lower.contains('torch') ||
        lower.contains('mmpose') ||
        lower.contains('mmcv') ||
        lower.contains('mmengine') ||
        lower.contains('skipped_no_smoothed') ||
        lower.contains('supabase_persist') ||
        lower.contains('first 45') ||
        lower.contains('gemini_report_failed') ||
        lower.contains('local_coaching_fallback') ||
        lower.contains('model_unavailable') ||
        lower.contains('detector_version') ||
        lower.contains('gemini_prompt');
  }

  @override
  Widget build(BuildContext context) {
    final coachNotes = results.limitations
        .where((l) => !_isInternalLimitation(l))
        .toList(growable: false);
    final usedLocal = results.limitations.any(
      (l) => l.toLowerCase().contains('local_coaching_fallback'),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('About this analysis', style: _h(context)),
        const SizedBox(height: 8),
        Text(
          usedLocal
              ? 'Coaching used SwimIQ local coach tips on this PC '
                  '(Gemini AI was unavailable for this run). '
                  'Pros/cons and dryland drills are still for the swimmer to use.'
              : 'Coaching was generated with Elite analysis on this PC.',
        ),
        const SizedBox(height: 12),
        Text(
          'Status: ${results.isFailed ? 'Needs another try' : 'Complete'}',
        ),
        if (_strokeLabel(results) != null) ...[
          const SizedBox(height: 6),
          Text('Stroke: ${_strokeLabel(results)}'),
        ],
        if (results.engineVersion.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Engine: ${results.engineVersion}'),
        ],
        if (coachNotes.isNotEmpty) ...[
          const SizedBox(height: 16),
          LimitationsPanel(
            title: 'Notes for the next film',
            limitations: coachNotes,
          ),
        ],
        if (results.evidence.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Key moments', style: _h(context)),
          const SizedBox(height: 8),
          ...results.evidence.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• ${e.displayLabel}'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Support ID (only if you need help): ${results.jobId}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  TextStyle? _h(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          );
}

/// Simple history list for prior V2 analyses.
class VideoAnalysisHistoryScreen extends ConsumerStatefulWidget {
  const VideoAnalysisHistoryScreen({super.key, required this.swimmerKey});

  final String swimmerKey;

  @override
  ConsumerState<VideoAnalysisHistoryScreen> createState() =>
      _VideoAnalysisHistoryScreenState();
}

class _VideoAnalysisHistoryScreenState
    extends ConsumerState<VideoAnalysisHistoryScreen> {
  List<AnalysisJob>? _jobs;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    ref.read(videoAnalyticsServiceProvider).logEvent(
      VideoAnalyticsService.historyOpened,
      {'swimmer_key': widget.swimmerKey},
    );
    try {
      final jobs = await ref
          .read(videoEngineV2ServiceProvider)
          .listHistory(widget.swimmerKey);
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis history')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      _error is VideoEngineV2Exception
                          ? (_error as VideoEngineV2Exception).message
                          : _error.toString(),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                )
              : (_jobs == null || _jobs!.isEmpty)
                  ? const EmptyStateMessage(
                      message: 'No prior Elite analyses yet.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _jobs!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final job = _jobs![index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          title: Text(job.stageLabel),
                          subtitle: Text(
                            '${job.status} · ${job.jobId.substring(0, job.jobId.length.clamp(0, 8))}…',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            if (job.isTerminal) {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => VideoAnalysisResultsScreen(
                                    jobId: job.jobId,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      VideoJobProgressScreen(jobId: job.jobId),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
    );
  }
}
