import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/video_engine_v2_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/video_engine_v2/video_engine_v2_models.dart';
import '../../../providers/video_engine_v2_provider.dart';
import '../../../widgets/swimiq_ui.dart';
import 'video_analysis_results_screen.dart';

/// Shows the live analysis stage label (no fake percentage animation).
class VideoJobProgressScreen extends ConsumerStatefulWidget {
  const VideoJobProgressScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<VideoJobProgressScreen> createState() =>
      _VideoJobProgressScreenState();
}

class _VideoJobProgressScreenState
    extends ConsumerState<VideoJobProgressScreen> {
  bool _navigated = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(videoEngineV2JobProvider.notifier).startPolling(widget.jobId);
    });
  }

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(videoEngineV2JobProvider.notifier).cancelActiveJob();
    } on VideoEngineV2Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  void _goToResults(AnalysisJob job) {
    if (_navigated || !mounted) return;
    _navigated = true;
    unawaited(
      ref.read(videoEngineV2JobProvider.notifier).stopPolling(keepState: true),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => VideoAnalysisResultsScreen(jobId: job.jobId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncJob = ref.watch(videoEngineV2JobProvider);

    ref.listen<AsyncValue<AnalysisJob?>>(videoEngineV2JobProvider, (_, next) {
      final job = next.valueOrNull;
      if (job != null && job.isTerminal) {
        _goToResults(job);
      }
    });

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          unawaited(
            ref
                .read(videoEngineV2JobProvider.notifier)
                .stopPolling(keepState: true),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analyzing'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: asyncJob.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SwimIqScreenHeader(
                  title: 'Analysis interrupted',
                  subtitle: 'We could not refresh job status.',
                ),
                const SizedBox(height: 16),
                Text(
                  e is VideoEngineV2Exception ? e.message : e.toString(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref
                      .read(videoEngineV2JobProvider.notifier)
                      .startPolling(widget.jobId),
                  child: const Text('Retry status check'),
                ),
              ],
            ),
            data: (job) {
              if (job == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SwimIqScreenHeader(
                    title: 'Elite Video Lab',
                    subtitle:
                        'We\'re analyzing your swim. The step below shows what we\'re working on right now.',
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          job.stageLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${job.status.replaceAll('_', ' ')}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (job.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            job.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (job.canCancel)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _cancelling ? null : _cancel,
                        child: Text(
                          _cancelling ? 'Cancelling…' : 'Cancel analysis',
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
