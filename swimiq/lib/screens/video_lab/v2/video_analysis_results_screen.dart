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
            'Priority improvements',
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
            'See the Coaching tab for drills and dryland suggestions.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
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
        lower.contains('gemini_report_failed');
  }

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

  @override
  Widget build(BuildContext context) {
    if (!results.hasDeterministicMetrics) {
      return const EmptyStateMessage(
        message: 'No metrics available for this analysis.',
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        section('Starts / underwater', startMetrics),
        section('Stroke', strokeMetrics),
        section('Turns / finishes', turnMetrics),
        section('Other metrics', otherMetrics),
        const SizedBox(height: 8),
        Text(
          'Confidence explanations',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'High confidence metrics are measured from clear evidence. '
          'Low confidence values are estimates and should not be treated as facts. '
          'Unavailable metrics show a reason instead of inventing a number.',
          style: Theme.of(context).textTheme.bodySmall,
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
          Text('Summary', style: _h(context)),
          const SizedBox(height: 6),
          Text(report.summary!),
          const SizedBox(height: 16),
        ],
        if (report.strengths.isNotEmpty) ...[
          Text('Strengths', style: _h(context)),
          const SizedBox(height: 6),
          ...report.strengths.map((s) => _bullet(s)),
          const SizedBox(height: 16),
        ],
        if (report.priorityImprovements.isNotEmpty) ...[
          Text('Priority improvements', style: _h(context)),
          const SizedBox(height: 6),
          ...report.priorityImprovements.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (p.evidenceMetricNames.isNotEmpty)
                    Text(
                      'Evidence: ${p.evidenceMetricNames.join(', ')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ...p.drills.map((d) => _bullet(d)),
                ],
              ),
            );
          }),
        ],
        if (report.drills.isNotEmpty) ...[
          Text('Drills', style: _h(context)),
          const SizedBox(height: 6),
          ...report.drills.map(_bullet),
          const SizedBox(height: 16),
        ],
        if (report.limitationsStatement?.trim().isNotEmpty == true) ...[
          Text('Report limitations', style: _h(context)),
          const SizedBox(height: 6),
          Text(report.limitationsStatement!),
        ],
        const SizedBox(height: 12),
        Text(
          'Coaching narrative is generated separately from measured metrics.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (results.limitations.isNotEmpty) ...[
          LimitationsPanel(limitations: results.limitations),
          const SizedBox(height: 16),
        ],
        Text('Evidence', style: _h(context)),
        const SizedBox(height: 8),
        if (results.evidence.isEmpty)
          const Text('No evidence frames listed.')
        else
          ...results.evidence.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• ${e.displayLabel}'),
            ),
          ),
        const SizedBox(height: 16),
        Text('Phases', style: _h(context)),
        const SizedBox(height: 8),
        if (results.phases.isEmpty)
          const Text('No phases detected.')
        else
          ...results.phases.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${p.displayName}'
                '${p.startMs != null ? ' · ${p.startMs}–${p.endMs ?? p.startMs} ms' : ''}'
                '${p.confidence != null ? ' · conf ${p.confidence!.toStringAsFixed(2)}' : ''}',
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text('Technical details', style: _h(context)),
        const SizedBox(height: 8),
        Text('Job: ${results.jobId}'),
        Text('Status: ${results.status}'),
        Text('Engine: ${results.engineVersion}'),
        if (results.videoId != null) Text('Video: ${results.videoId}'),
        if (results.modelVersions.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...results.modelVersions.entries.map(
            (e) => Text('${e.key}: ${e.value}'),
          ),
        ],
        if (results.stroke != null) ...[
          const SizedBox(height: 8),
          Text('Stroke hint: ${results.stroke}'),
        ],
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
