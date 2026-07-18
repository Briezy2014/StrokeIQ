import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/video_analytics_service.dart';
import '../../../core/services/video_engine_v2_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/video_models.dart';
import '../../../providers/app_providers.dart';
import 'video_job_progress_screen.dart';

/// Bottom sheet / page to confirm stroke/distance/course and start V2 analysis.
class VideoEngineV2SetupSheet extends ConsumerStatefulWidget {
  const VideoEngineV2SetupSheet({
    super.key,
    required this.video,
    this.swimmerKey,
    this.displayName,
  });

  final SwimVideo video;
  final String? swimmerKey;
  final String? displayName;

  static Future<void> open(
    BuildContext context, {
    required SwimVideo video,
    String? swimmerKey,
    String? displayName,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoEngineV2SetupSheet(
          video: video,
          swimmerKey: swimmerKey,
          displayName: displayName,
        ),
      ),
    );
  }

  @override
  ConsumerState<VideoEngineV2SetupSheet> createState() =>
      _VideoEngineV2SetupSheetState();
}

class _VideoEngineV2SetupSheetState
    extends ConsumerState<VideoEngineV2SetupSheet> {
  late final TextEditingController _strokeController;
  late final TextEditingController _distanceController;
  late final TextEditingController _courseController;
  late final TextEditingController _targetTrackController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _strokeController =
        TextEditingController(text: widget.video.stroke ?? 'Butterfly');
    _distanceController =
        TextEditingController(text: widget.video.distance ?? '50');
    _courseController =
        TextEditingController(text: widget.video.course ?? 'LCM');
    _targetTrackController = TextEditingController();
  }

  @override
  void dispose() {
    _strokeController.dispose();
    _distanceController.dispose();
    _courseController.dispose();
    _targetTrackController.dispose();
    super.dispose();
  }

  Future<void> _confirmAnalyze() async {
    final videoId = widget.video.id;
    if (videoId == null || videoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video must be saved before analysis.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final analytics = ref.read(videoAnalyticsServiceProvider);
    try {
      final service = ref.read(videoEngineV2ServiceProvider);
      final health = await service.checkHealth();
      if (!health.reachable || !health.mediaToolsReady) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(health.message),
            duration: const Duration(seconds: 12),
          ),
        );
        return;
      }

      final targetTrack = _targetTrackController.text.trim();
      final job = await service.createJob(
        videoId: videoId,
        storagePath: widget.video.storagePath,
        swimmerKey: widget.swimmerKey ?? widget.video.swimmer,
        displayName: widget.displayName ?? widget.video.swimmer,
        stroke: _strokeController.text.trim(),
        distanceM: int.tryParse(_distanceController.text.trim()),
        course: _courseController.text.trim(),
        title: widget.video.title,
        notes: widget.video.notes,
        targetTrackId: targetTrack.isEmpty ? null : targetTrack,
        generateGeminiReport: true,
      );
      analytics.logEvent(VideoAnalyticsService.analysisJobCreated, {
        'job_id': job.jobId,
        'video_id': videoId,
        'stage': job.stage,
      });

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => VideoJobProgressScreen(jobId: job.jobId),
        ),
      );
    } on VideoEngineV2Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          duration: const Duration(seconds: 12),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elite Video Lab'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Confirm analysis setup',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.video.displayTitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _strokeController,
            decoration: const InputDecoration(
              labelText: 'Stroke',
              hintText: 'Butterfly, Freestyle, Backstroke, Breaststroke, IM',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _distanceController,
            decoration: const InputDecoration(labelText: 'Distance (m)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _courseController,
            decoration: const InputDecoration(
              labelText: 'Course',
              hintText: 'SCY, SCM, or LCM',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _targetTrackController,
            decoration: const InputDecoration(
              labelText: 'Target track ID (optional)',
              hintText: 'Leave blank for automatic selection',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submitting ? null : _confirmAnalyze,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.analytics_outlined),
            label: Text(_submitting ? 'Starting…' : 'Confirm & analyze'),
          ),
        ],
      ),
    );
  }
}
