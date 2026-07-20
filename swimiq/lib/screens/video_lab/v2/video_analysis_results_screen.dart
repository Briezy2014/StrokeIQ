import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/video_analytics_service.dart';
import '../../../core/services/video_engine_v2_service.dart';
import '../../../data/models/video_engine_v2/video_engine_v2_models.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/swimmer_data_provider.dart';
import '../../../widgets/coaching_report_view.dart';
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
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _videoUrl = null;
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
      // Non-blocking: Race Blueprint still works if signed URL fails.
      unawaited(_loadSignedVideoUrl());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadSignedVideoUrl() async {
    try {
      final url = await ref
          .read(videoEngineV2ServiceProvider)
          .signedVideoUrl(widget.jobId);
      if (!mounted) return;
      setState(() => _videoUrl = url);
    } catch (_) {
      // Preview is optional — do not surface as a hard results error.
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

  String get _athleteName {
    final swimmer = ref.watch(activeSwimmerProvider);
    final data = ref.watch(swimmerDataProvider).value;
    final fromResults = _results?.athlete?['display_name']?.toString().trim();
    if (fromResults != null &&
        fromResults.isNotEmpty &&
        fromResults.toLowerCase() != 'demo' &&
        fromResults.toLowerCase() != 'you') {
      return fromResults;
    }
    if (data?.profile != null) {
      return data!.profile!.recruitingCardName(fallbackSwimmerKey: swimmer);
    }
    if (swimmer != null &&
        swimmer.trim().isNotEmpty &&
        swimmer.toLowerCase() != 'demo') {
      return data?.displayName(swimmer) ?? swimmer;
    }
    return 'Athlete';
  }

  @override
  Widget build(BuildContext context) {
    final name = _athleteName;
    final title = name == 'Athlete' || name == 'Add athlete name'
        ? 'Your coaching report'
        : "$name's coaching report";
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(athleteName: name),
    );
  }

  Widget _buildBody({required String athleteName}) {
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
      final code = (results.errorCode ?? '').toUpperCase();
      final rawMessage = results.errorMessage ?? '';
      final isPoseSoftIssue = code.contains('POSE') ||
          rawMessage.toLowerCase().contains('pose dependency') ||
          rawMessage.toLowerCase().contains('no module named');
      final friendly = VideoEngineV2Service.userMessageForErrorCode(
        isPoseSoftIssue ? 'POSE_DEPS_MISSING' : results.errorCode,
        fallback: results.errorMessage ??
            'SwimIQ could not analyze this video. Please try again with a clearer side-view clip.',
      );
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwimIqScreenHeader(
            title: isPoseSoftIssue
                ? 'Almost ready — retry for your coaching report'
                : 'This video could not be analyzed',
            subtitle: friendly,
          ),
          const SizedBox(height: 16),
          if (results.isClipQualityFailure && !isPoseSoftIssue) ...[
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

    return _SwimmerReport(
      results: results,
      athleteName: athleteName,
      onRetry: _retry,
      retrying: _retrying,
      videoUrl: _videoUrl,
    );
  }
}

class _SwimmerReport extends StatelessWidget {
  const _SwimmerReport({
    required this.results,
    required this.athleteName,
    required this.onRetry,
    required this.retrying,
    this.videoUrl,
  });

  final AnalysisResults results;
  final String athleteName;
  final VoidCallback onRetry;
  final bool retrying;
  final String? videoUrl;

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

    return CoachingReportView(
      results: results,
      athleteName: athleteName,
      onRetry: onRetry,
      retrying: retrying,
      videoUrl: videoUrl,
    );
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
                            '${job.statusLabel} · ${job.jobId.substring(0, job.jobId.length.clamp(0, 8))}…',
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
