import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/video_analytics_service.dart';
import '../../../core/services/video_engine_v2_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/video_engine_v2/video_engine_v2_models.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/swimiq_ui.dart';
import 'video_job_progress_screen.dart';

/// Results viewer for Video Engine V2 jobs — one swimmer-facing report.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your coaching report'),
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

    if (results.isCancelled) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SwimIqScreenHeader(
            title: 'Analysis cancelled',
            subtitle:
                'This video was not analyzed. Start a new analysis from Video Lab when you are ready.',
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Back to Video Lab'),
          ),
        ],
      );
    }

    if (results.isFailed && results.report == null) {
      final friendly = VideoEngineV2Service.userMessageForErrorCode(
        results.errorCode,
        fallback: results.errorMessage ??
            'SwimIQ could not analyze this video. Please try again with a clearer side-view clip.',
      );
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwimIqScreenHeader(
            title: 'This video could not be analyzed',
            subtitle: friendly,
          ),
          const SizedBox(height: 16),
          if (results.isClipQualityFailure) ...[
            Text(
              'Film from the side, keep the whole body in view, and hold the camera steady.',
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

    return _SwimmerReport(results: results, onRetry: _retry, retrying: _retrying);
  }
}

class _SwimmerReport extends StatelessWidget {
  const _SwimmerReport({
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
    final hasSummary = report?.summary?.trim().isNotEmpty == true;
    final hasStrengths = report?.strengths.isNotEmpty == true;
    final hasImprovements = report?.priorityImprovements.isNotEmpty == true;
    final hasRace = report?.raceRecommendations.isNotEmpty == true;

    if (report == null ||
        (!hasSummary && !hasStrengths && !hasImprovements && !hasRace)) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwimIqScreenHeader(
            title: 'This video could not be analyzed',
            subtitle: VideoEngineV2Service.userMessageForErrorCode(
              _geminiFailureCodeFromResults(results) ??
                  'GEMINI_REPORT_UNAVAILABLE',
              fallback:
                  'SwimIQ could not build a coaching report for this clip. '
                  'Please try again or upload a clearer side-view video.',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: retrying ? null : onRetry,
            child: Text(retrying ? 'Retrying…' : 'Retry analysis'),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (results.isFailed || results.isPartialSuccess) ...[
          Card(
            color: const Color(0xFFFFF7ED),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    results.isFailed
                        ? Icons.error_outline
                        : Icons.info_outline,
                    color: results.isFailed
                        ? const Color(0xFFC2410C)
                        : AppColors.primaryDark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      results.isFailed
                          ? 'Analysis did not finish successfully. The notes below may be incomplete — do not treat them as a full coaching report.'
                          : 'Analysis finished with limitations. Review the coaching notes, then re-film if something looks off.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (hasSummary) ...[
          Text(report.summary!, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: AppColors.primaryDark,
              )),
          const SizedBox(height: 20),
        ],
        if (hasStrengths) ...[
          Text('Keep doing this', style: _h(context)),
          const SizedBox(height: 8),
          ...report.strengths.map(_bullet),
          const SizedBox(height: 20),
        ],
        if (hasImprovements) ...[
          Text('Fix this next', style: _h(context)),
          const SizedBox(height: 8),
          ...report.priorityImprovements.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  if (p.drills.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Dryland',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                    ),
                    const SizedBox(height: 4),
                    ...p.drills.map(_bullet),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
        if (hasRace) ...[
          Text('Next race', style: _h(context)),
          const SizedBox(height: 8),
          ...report.raceRecommendations.map(_bullet),
        ],
        if (results.isFailed) ...[
          const SizedBox(height: 24),
          FilledButton(
            onPressed: retrying ? null : onRetry,
            child: Text(retrying ? 'Retrying…' : 'Retry analysis'),
          ),
        ],
      ],
    );
  }

  TextStyle? _h(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDark,
          );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• '),
            Expanded(
              child: Text(text, style: const TextStyle(height: 1.35)),
            ),
          ],
        ),
      );
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
