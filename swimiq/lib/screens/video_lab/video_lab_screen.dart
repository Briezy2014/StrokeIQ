import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../config/env.dart';
import '../../config/feature_flags.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/subscription_plan.dart';
import '../../core/services/gemini_swim_analysis_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/video_analytics_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/subscription/subscription_capabilities.dart';
import '../../core/utils/motivational_cut.dart';
import '../../core/utils/swim_stroke_utils.dart';
import '../../core/utils/video_event_inference.dart';
import '../../data/models/video_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../providers/video_server_health_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/ai_data_consent_dialog.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_media_picker.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../../widgets/swimiq_ui.dart';
import '../../widgets/video_analysis_report.dart';
import '../../core/services/video_engine_v2_service.dart';
import '../membership/membership_screen.dart';
import 'v2/video_analysis_results_screen.dart';
import 'v2/video_job_progress_screen.dart';

class VideoLabScreen extends ConsumerStatefulWidget {
  const VideoLabScreen({super.key});

  @override
  ConsumerState<VideoLabScreen> createState() => _VideoLabScreenState();
}

class _VideoLabScreenState extends ConsumerState<VideoLabScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _distanceController = TextEditingController(text: '50');
  final _strokeController = TextEditingController(text: 'Butterfly');
  final _courseController = TextEditingController(text: 'LCM');
  bool _uploading = false;
  String? _analyzingVideoId;
  bool _clearedPlaceholders = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearStalePlaceholderAnalysesOnce();
    });
  }

  Future<void> _clearStalePlaceholderAnalysesOnce() async {
    if (_clearedPlaceholders || !mounted) return;
    _clearedPlaceholders = true;
    await ref
        .read(swimmerDataProvider.notifier)
        .clearPlaceholderVideoAnalyses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _distanceController.dispose();
    _strokeController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  String get _stroke => _strokeController.text.trim().isEmpty
      ? 'Butterfly'
      : _strokeController.text.trim();

  String get _course => _courseController.text.trim().isEmpty
      ? 'LCM'
      : _courseController.text.trim();

  void _applyEventInference(String? title) {
    final inferred = VideoEventInference.fromTitle(title);
    if (inferred.stroke != null) {
      _strokeController.text = inferred.stroke!;
    }
    if (inferred.course != null) {
      _courseController.text = inferred.course!;
    }
    if (inferred.distance != null) {
      _distanceController.text = '${inferred.distance}';
    }
  }

  Future<void> _pickAndUpload() async {
    final picked = await pickSwimIqMedia(context, kind: SwimIqMediaKind.video);
    if (picked == null) return;

    final fileName = picked.fileName;
    if (_titleController.text.trim().isEmpty) {
      _titleController.text = fileName;
    }
    _applyEventInference(fileName);
    setState(() {});

    setState(() => _uploading = true);
    final analytics = ref.read(videoAnalyticsServiceProvider);
    analytics.logEvent(VideoAnalyticsService.uploadStarted, {
      'file_name': fileName,
      'byte_length': picked.bytes.length,
    });
    final distance = int.tryParse(_distanceController.text.trim()) ?? 50;
    final error = await ref
        .read(swimmerDataProvider.notifier)
        .uploadVideo(
          fileName: fileName,
          bytes: picked.bytes,
          title: _titleController.text.trim().isEmpty
              ? fileName
              : _titleController.text.trim(),
          stroke: _stroke,
          distance: '$distance',
          course: _course,
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _uploading = false);

    if (error == null) {
      analytics.logEvent(VideoAnalyticsService.uploadSucceeded, {
        'file_name': fileName,
      });
    } else {
      analytics.logEvent(VideoAnalyticsService.uploadFailed, {
        'file_name': fileName,
        'error': error,
      });
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Video uploaded.')));

    if (error == null) {
      _titleController.clear();
      _notesController.clear();
    }
  }

  Future<void> _deleteVideo(SwimVideo video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this video?'),
        content: const Text(
          'This removes the video and any saved AI analysis. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(swimmerDataProvider.notifier)
        .deleteVideo(video);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Video deleted.')));
  }

  Future<void> _startEliteAnalysis(SwimVideo video) async {
    final videoId = video.id;
    if (videoId == null || videoId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video must be saved before analysis.')),
      );
      return;
    }
    if (video.storagePath.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This video did not finish uploading. Upload again, wait until it '
            'appears in the list, then run analysis.',
          ),
          duration: Duration(seconds: 12),
        ),
      );
      return;
    }

    setState(() => _analyzingVideoId = videoId);
    final analytics = ref.read(videoAnalyticsServiceProvider);
    final swimmer = ref.read(activeSwimmerProvider);
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
      if (!health.storageConfigured) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(health.message),
            duration: const Duration(seconds: 14),
          ),
        );
        return;
      }

      final swimmerKey = swimmer ?? video.swimmer;
      final swimmerData = ref.read(swimmerDataProvider).value;
      final resolvedName = swimmerData?.profile
              ?.recruitingCardName(fallbackSwimmerKey: swimmerKey) ??
          (swimmerKey != null
              ? swimmerData?.displayName(swimmerKey)
              : null) ??
          swimmerKey;
      final job = await service.createJob(
        videoId: videoId,
        storagePath: video.storagePath,
        swimmerKey: swimmerKey,
        displayName: resolvedName,
        stroke: video.stroke ?? _strokeController.text.trim(),
        distanceM: video.distanceMeters ??
            int.tryParse(_distanceController.text.trim()),
        course: video.course ?? _courseController.text.trim(),
        title: video.title,
        notes: video.notes,
        generateGeminiReport: true,
      );
      analytics.logEvent(VideoAnalyticsService.analysisJobCreated, {
        'job_id': job.jobId,
        'video_id': videoId,
        'stage': job.stage,
      });

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VideoJobProgressScreen(jobId: job.jobId),
        ),
      );
    } on VideoEngineV2Exception catch (e) {
      if (!mounted) return;
      final message =
          VideoEngineV2Service.sanitizeUserFacingError(e.message) ?? e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 12),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      final message =
          VideoEngineV2Service.sanitizeUserFacingError(raw) ?? raw;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _analyzingVideoId = null);
    }
  }

  Future<void> _runAnalysis(SwimVideo video, {bool forceLegacy = false}) async {
    final videoId = video.id;
    if (videoId == null) return;

    final subscription = ref.read(subscriptionStateProvider).value;
    final email = ref.read(currentUserProvider)?.email;
    final v2Allowed = FeatureFlags.isVideoEngineV2Allowed(
      email: email,
      subscription: subscription,
    );

    // Local Elite CV only on this PC (not the public website). Website users
    // get cloud AI coaching — never .bat / 127.0.0.1 instructions.
    final preferLocalElite =
        v2Allowed && !forceLegacy && !Env.isPublicHostedWeb;
    if (preferLocalElite) {
      final elite = await ref.read(videoEngineV2ServiceProvider).checkHealth();
      final eliteReady = elite.reachable &&
          elite.mediaToolsReady &&
          elite.storageConfigured;
      if (eliteReady) {
        if (!mounted) return;
        final consented = await AiDataConsentDialog.ensureGranted(context);
        if (!consented || !mounted) return;
        await _startEliteAnalysis(video);
        return;
      }

      if (!FeatureFlags.videoEngineLegacyEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Elite analysis is not ready yet. Start SwimIQ with Elite, leave '
              'the Elite server window open, then try again.',
            ),
            duration: Duration(seconds: 10),
          ),
        );
        return;
      }
    }

    if (subscription != null &&
        !SubscriptionCapabilities.canRunSwimIqAiAnalysis(subscription)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            SubscriptionCapabilities.eliteGateMessage(subscription),
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    final consented = await AiDataConsentDialog.ensureGranted(context);
    if (!consented || !mounted) return;

    setState(() => _analyzingVideoId = videoId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sending your clip to Gemini for AI coaching (usually under 2 minutes). '
            'Keep this tab open.',
          ),
          duration: Duration(seconds: 8),
        ),
      );
    }

    String? error;
    try {
      error = await ref.read(swimmerDataProvider.notifier).analyzeVideo(video);
    } finally {
      if (mounted) {
        setState(() => _analyzingVideoId = null);
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'AI analysis saved.'),
        duration: Duration(seconds: error != null ? 10 : 4),
      ),
    );
  }

  String? _videoMotivationalCut(SwimmerData data, SwimVideo video) {
    final stroke = SwimStrokeUtils.canonical(video.stroke);
    final distance = int.tryParse(video.distance ?? '');
    final course = video.course?.trim();
    if (stroke.isEmpty ||
        distance == null ||
        course == null ||
        course.isEmpty) {
      return null;
    }

    final matches = data.personalBests.where(
      (log) =>
          log.stroke == stroke &&
          log.distance == distance &&
          log.course == course,
    );
    if (matches.isEmpty) return null;

    return MotivationalCut.labelForSwim(
      catalog: data.motivationalStandards,
      profile: data.profile,
      stroke: stroke,
      distance: distance,
      course: course,
      timeSeconds: matches.first.timeSeconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final dateFormat = DateFormat.yMMMd();
        final videos = data.userFacingVideos;
        final snapshot = data.passportSnapshot(swimmer);
        final email = ref.watch(currentUserProvider)?.email;
        final subscription = ref.watch(subscriptionStateProvider).value;
        final canRunAi =
            subscription != null &&
            SubscriptionCapabilities.canRunSwimIqAiAnalysis(subscription);
        final hasPro =
            subscription != null &&
            SubscriptionCapabilities.canUseProFeatures(subscription);
        final v2Allowed = FeatureFlags.isVideoEngineV2Allowed(
          email: email,
          subscription: subscription,
        );
        final dualRun = v2Allowed && FeatureFlags.videoEngineLegacyEnabled;
        final serverHealthAsync = ref.watch(videoServerHealthProvider);
        final serverHealth = serverHealthAsync.valueOrNull;
        final hosted = Env.isPublicHostedWeb;
        final heroSubtitle = hosted
            ? (canRunAi
                ? 'Upload race video for AI coaching'
                : hasPro
                    ? 'Upload & review — AI coaching is Elite'
                    : 'Pro unlocks video library')
            : v2Allowed
                ? 'Elite stroke analysis from your race footage'
                : canRunAi
                    ? 'AI coaching from your race footage'
                    : hasPro
                        ? 'Upload & review — AI analysis is Elite'
                        : 'Pro unlocks video library';

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqPageHero(
              showMark: false,
              title: hosted
                  ? 'Video Lab'
                  : (v2Allowed ? 'Elite Video Lab' : 'Video Lab'),
              subtitle: heroSubtitle,
              stats: [
                SwimIqHeroStat('${videos.length} videos'),
                SwimIqHeroStat(
                  '${data.userFacingVideoAnalyses.length} analyses',
                ),
              ],
            ),
            // Public website: only promise cloud AI when the account can run it.
            if (hosted && canRunAi) ...[
              const SizedBox(height: 12),
              Material(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_done_outlined,
                        color: Color(0xFF1B5E20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'AI coaching is ready in the cloud. '
                          'Upload a race clip and tap Analyze — no software to install.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF1B5E20),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Local Elite status banner only on this PC (not swimiqapp.com).
            if (!hosted && v2Allowed) ...[
              const SizedBox(height: 12),
              _EliteServerStatusBanner(
                health: serverHealth,
                onRetry: () => ref.invalidate(videoServerHealthProvider),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            VideoAnalysisHistoryScreen(swimmerKey: swimmer),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Analysis history'),
                ),
              ),
            ],
            // Pro users without Elite should still see the upgrade path on web.
            if (!AppConstants.unlockAllTabsForPreview &&
                hasPro &&
                !canRunAi &&
                (hosted || !v2Allowed)) ...[
              const SizedBox(height: 12),
              _VideoLabEliteBanner(subscription: subscription),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Video title'),
              onChanged: _applyEventInference,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _strokeController,
              decoration: const InputDecoration(
                labelText: 'Stroke',
                hintText:
                    'Freestyle, Backstroke, Breaststroke, Butterfly, or IM',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _distanceController,
              decoration: const InputDecoration(labelText: 'Distance'),
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
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Race notes',
                hintText:
                    'Reaction time, breakout, breathing, stroke count, tempo, finish, race strategy...',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined),
              label: const Text('Upload Swim Video'),
            ),
            const SizedBox(height: 8),
            Text(
              'Camera, gallery, or file — pick what works on your device.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            Text('Your Videos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(snapshot.latestAnalysisSummary),
            const SizedBox(height: 12),
            if (videos.isEmpty)
              const EmptyStateMessage(
                message:
                    'No videos yet. Upload a swim video to build your library. '
                    'Elite unlocks AI stroke analysis.',
              )
            else
              ...videos.map(
                (video) => _VideoCard(
                  video: video,
                  analysis: data.analysisForVideo(video.id),
                  serverHealth: serverHealth,
                  dateFormat: dateFormat,
                  analyzing: _analyzingVideoId == video.id,
                  onAnalyze: () => _runAnalysis(video),
                  onDelete: () => _deleteVideo(video),
                  canRunAi: canRunAi,
                  onLegacyAnalyze: dualRun
                      ? () => _runAnalysis(video, forceLegacy: true)
                      : null,
                  // Public website uses cloud AI labeling, not local "Elite Analysis".
                  v2Primary: !hosted && v2Allowed,
                  motivationalCut: _videoMotivationalCut(data, video),
                  onCoachNotesChanged: video.id == null
                      ? null
                      : (notes) => ref
                            .read(swimmerDataProvider.notifier)
                            .updateAnalysisCoachNotes(
                              videoId: video.id!,
                              notes: notes,
                            ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EliteServerStatusBanner extends StatelessWidget {
  const _EliteServerStatusBanner({
    required this.health,
    required this.onRetry,
  });

  final VideoAnalysisServerHealth? health;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ready = health?.ok == true;
    final message = health?.message ??
        'Checking Elite analysis server at ${Env.analysisApiBaseUrl} …';
    final bg = ready ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final fg = ready ? const Color(0xFF1B5E20) : const Color(0xFFE65100);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              ready ? Icons.check_circle_outline : Icons.wifi_off_outlined,
              color: fg,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ready
                    ? 'Elite server connected. $message'
                    : 'Elite server not ready. $message',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Recheck'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoLabEliteBanner extends StatelessWidget {
  const _VideoLabEliteBanner({this.subscription});

  final SubscriptionState? subscription;

  @override
  Widget build(BuildContext context) {
    final elite = SubscriptionCatalog.planFor(SubscriptionTier.elite);
    final message = subscription != null
        ? SubscriptionCapabilities.eliteGateMessage(subscription!)
        : 'SwimIQ Elite unlocks AI video analysis, Race Intelligence, and '
              'advanced performance planning.';

    return Card(
      color: AppColors.textDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  elite.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textDark,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MembershipScreen(),
                  ),
                );
              },
              child: Text('Upgrade to ${elite.name}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoCard extends ConsumerStatefulWidget {
  const _VideoCard({
    required this.video,
    required this.analysis,
    required this.serverHealth,
    required this.dateFormat,
    required this.analyzing,
    required this.onAnalyze,
    required this.onDelete,
    required this.canRunAi,
    this.onLegacyAnalyze,
    this.v2Primary = false,
    this.motivationalCut,
    this.onCoachNotesChanged,
  });

  final SwimVideo video;
  final SwimVideoAnalysis? analysis;
  final VideoAnalysisServerHealth? serverHealth;
  final DateFormat dateFormat;
  final bool analyzing;
  final VoidCallback onAnalyze;
  final VoidCallback onDelete;
  final bool canRunAi;
  final VoidCallback? onLegacyAnalyze;
  final bool v2Primary;
  final String? motivationalCut;
  final ValueChanged<String>? onCoachNotesChanged;

  @override
  ConsumerState<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends ConsumerState<_VideoCard> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    String? url = widget.video.videoUrl;
    try {
      url = await ref
          .read(videoStorageServiceProvider)
          .resolvePlaybackUrl(widget.video);
    } catch (_) {
      // Widget tests / pre-Supabase boot: keep stored URL fallback.
    }
    if (!mounted || url == null || url.isEmpty) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
    } catch (_) {
      await controller.dispose();
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.video.displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Video options',
                  onSelected: (value) {
                    if (value == 'delete') widget.onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                          SizedBox(width: 8),
                          Text(
                            'Delete video',
                            style: TextStyle(color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.video.createdAt != null)
              Text(widget.dateFormat.format(widget.video.createdAt!)),
            if (widget.motivationalCut != null)
              Text(
                'Motivational cut from matching PB: ${widget.motivationalCut}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (_controller != null) ...[
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _controller!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller!.value.isPlaying
                            ? _controller!.pause()
                            : _controller!.play();
                      });
                    },
                  ),
                ],
              ),
            ],
            _AnalysisActionButton(
              analyzing: widget.analyzing,
              canRunAi: widget.canRunAi,
              hasAnalysis: widget.analysis != null,
              v2Primary: widget.v2Primary,
              onAnalyze: widget.onAnalyze,
            ),
            if (widget.onLegacyAnalyze != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.analyzing ? null : widget.onLegacyAnalyze,
                child: Text(
                  widget.canRunAi
                      ? 'Run legacy analysis'
                      : 'Run legacy analysis (Elite)',
                ),
              ),
            ],
            if (widget.analyzing) ...[
              const SizedBox(height: 12),
              const _AnalysisInProgressCard(),
            ] else if (widget.analysis != null) ...[
              const SizedBox(height: 12),
              VideoAnalysisReport(
                analysis: widget.analysis!,
                serverHealth: widget.serverHealth,
                onCoachNotesChanged: widget.onCoachNotesChanged ?? (_) {},
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete_forever_outlined, size: 20),
              label: const Text('Delete video'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFDC2626)),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisActionButton extends StatelessWidget {
  const _AnalysisActionButton({
    required this.analyzing,
    required this.canRunAi,
    required this.hasAnalysis,
    required this.onAnalyze,
    this.v2Primary = false,
  });

  final bool analyzing;
  final bool canRunAi;
  final bool hasAnalysis;
  final VoidCallback onAnalyze;
  final bool v2Primary;

  @override
  Widget build(BuildContext context) {
    String label;
    if (v2Primary) {
      label = hasAnalysis ? 'Run Elite Analysis again' : 'Run Elite Analysis';
    } else if (canRunAi) {
      label = hasAnalysis ? 'Analyze again' : 'Run AI Swim Analysis';
    } else {
      label = hasAnalysis
          ? 'Analyze again (Elite)'
          : 'Run AI Swim Analysis (Elite)';
    }

    return FilledButton.tonalIcon(
      onPressed: analyzing ? null : onAnalyze,
      icon: analyzing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              v2Primary || canRunAi ? Icons.auto_awesome : Icons.lock_outline,
              size: 18,
            ),
      label: Text(label),
    );
  }
}

class _AnalysisInProgressCard extends StatelessWidget {
  const _AnalysisInProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyzing your clip...',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gemini is watching your video on the server. This usually finishes '
                  'in under 2 minutes — keep this tab open. Keep files under '
                  '${AppConstants.maxGeminiVideoMb} MB (720p works best — short 4K clips can still be too large).',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
