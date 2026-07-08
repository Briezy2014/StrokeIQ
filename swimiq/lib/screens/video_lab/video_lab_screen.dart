import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../core/utils/motivational_cut.dart';
import '../../core/utils/swim_stroke_utils.dart';
import '../../core/utils/video_event_inference.dart';
import '../../core/constants/swimiq_quotes.dart';
import '../../core/models/subscription_plan.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/video_models.dart';
import '../../core/subscription/subscription_capabilities.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/ai_data_consent_dialog.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../../widgets/swimiq_ui.dart';
import '../../widgets/video_analysis_report.dart';
import '../membership/membership_screen.dart';

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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final fileName = file.name;
    if (_titleController.text.trim().isEmpty) {
      _titleController.text = fileName;
    }
    _applyEventInference(fileName);
    setState(() {});

    if (file.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read video bytes. Try a smaller file.'),
        ),
      );
      return;
    }

    setState(() => _uploading = true);
    final distance = int.tryParse(_distanceController.text.trim()) ?? 50;
    final error = await ref.read(swimmerDataProvider.notifier).uploadVideo(
          fileName: fileName,
          bytes: file.bytes!,
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Video uploaded.'),
      ),
    );

    if (error == null) {
      _titleController.clear();
      _notesController.clear();
    }
  }

  Future<void> _runAnalysis(SwimVideo video) async {
    final videoId = video.id;
    if (videoId == null) return;

    final subscription = ref.read(subscriptionStateProvider).value;
    if (subscription != null &&
        !SubscriptionCapabilities.canRunSwimIqAiAnalysis(subscription)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SubscriptionCapabilities.eliteGateMessage(subscription)),
        ),
      );
      return;
    }

    final consented = await AiDataConsentDialog.ensureGranted(context);
    if (!consented || !mounted) return;

    setState(() => _analyzingVideoId = videoId);
    final error = await ref.read(swimmerDataProvider.notifier).analyzeVideo(video);
    if (!mounted) return;
    setState(() => _analyzingVideoId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'AI analysis saved.')),
    );
  }

  String? _videoMotivationalCut(SwimmerData data, SwimVideo video) {
    final stroke = SwimStrokeUtils.canonical(video.stroke);
    final distance = int.tryParse(video.distance ?? '');
    final course = video.course?.trim();
    if (stroke.isEmpty || distance == null || course == null || course.isEmpty) {
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
        final subscription = ref.watch(subscriptionStateProvider).value;
        final canRunAi = subscription != null &&
            SubscriptionCapabilities.canRunSwimIqAiAnalysis(subscription);
        final hasPro = subscription != null &&
            SubscriptionCapabilities.canUseProFeatures(subscription);

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqPageHero(
              title: 'Video Lab',
              subtitle: canRunAi
                  ? 'AI coaching from your race footage'
                  : hasPro
                      ? 'Upload & review — AI analysis is Elite'
                      : 'Pro unlocks video library',
              quote: SwimIqQuotes.pickFor(swimmer, SwimIqQuotes.videoLab),
              stats: [
                SwimIqHeroStat('${videos.length} videos'),
                SwimIqHeroStat('${data.userFacingVideoAnalyses.length} analyses'),
              ],
            ),
            if (hasPro && !canRunAi) ...[
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
                  : const Icon(Icons.upload_file),
              label: const Text('Upload Swim Video'),
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
                  dateFormat: dateFormat,
                  analyzing: _analyzingVideoId == video.id,
                  onAnalyze: () => _runAnalysis(video),
                  canRunAi: canRunAi,
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

class _VideoCard extends StatefulWidget {
  const _VideoCard({
    required this.video,
    required this.analysis,
    required this.dateFormat,
    required this.analyzing,
    required this.onAnalyze,
    required this.canRunAi,
    this.motivationalCut,
    this.onCoachNotesChanged,
  });

  final SwimVideo video;
  final SwimVideoAnalysis? analysis;
  final DateFormat dateFormat;
  final bool analyzing;
  final VoidCallback onAnalyze;
  final bool canRunAi;
  final String? motivationalCut;
  final ValueChanged<String>? onCoachNotesChanged;

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.video.videoUrl;
    if (url == null || url.isEmpty) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    if (!mounted) return;
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
            Text(widget.video.displayTitle,
                style: const TextStyle(fontWeight: FontWeight.w800)),
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
            if (widget.analysis == null)
              FilledButton.tonalIcon(
                onPressed: widget.analyzing ? null : widget.onAnalyze,
                icon: widget.analyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        widget.canRunAi ? Icons.auto_awesome : Icons.lock_outline,
                        size: 18,
                      ),
                label: Text(
                  widget.canRunAi
                      ? 'Run AI Swim Analysis'
                      : 'Run AI Swim Analysis (Elite)',
                ),
              )
            else ...[
              const SizedBox(height: 12),
              VideoAnalysisReport(
                analysis: widget.analysis!,
                onCoachNotesChanged: widget.onCoachNotesChanged ?? (_) {},
              ),
            ],
          ],
        ),
      ),
    );
  }
}
