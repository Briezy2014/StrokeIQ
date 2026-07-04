import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/swim_video.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/common_widgets.dart';

class VideoLabScreen extends ConsumerStatefulWidget {
  const VideoLabScreen({super.key, required this.data});

  final SwimmerData data;

  @override
  ConsumerState<VideoLabScreen> createState() => _VideoLabScreenState();
}

class _VideoLabScreenState extends ConsumerState<VideoLabScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  String _stroke = AppConstants.strokes.first;
  String _course = AppConstants.courses.first;
  int _distance = 100;
  bool _uploading = false;
  bool _analyzing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
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
    final error = await ref.read(swimmerDataProvider.notifier).uploadVideo(
          fileName: file.name,
          bytes: file.bytes!,
          title: _titleController.text.trim().isEmpty
              ? file.name
              : _titleController.text.trim(),
          stroke: _stroke,
          distance: _distance,
          course: _course,
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _uploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              'Video uploaded. If upload failed, run the Supabase migration and create the swim-videos bucket.',
        ),
      ),
    );

    if (error == null) {
      _titleController.clear();
      _notesController.clear();
    }
  }

  Future<void> _runAnalysis(SwimVideo video) async {
    setState(() => _analyzing = true);
    final error = await ref.read(swimmerDataProvider.notifier).analyzeVideo(video);
    if (!mounted) return;
    setState(() => _analyzing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'AI analysis saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Video Lab',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload swim videos for playback and AI coaching analysis.',
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Video title'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _stroke,
          decoration: const InputDecoration(labelText: 'Stroke'),
          items: AppConstants.strokes
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _stroke = v!),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: '100',
          decoration: const InputDecoration(labelText: 'Distance'),
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final parsed = int.tryParse(v);
            if (parsed != null) _distance = parsed;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _course,
          decoration: const InputDecoration(labelText: 'Course'),
          items: AppConstants.courses
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _course = v!),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText: 'Stroke count, splits, race notes...',
          ),
          maxLines: 2,
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
        const SizedBox(height: 12),
        if (widget.data.videos.isEmpty)
          const EmptyStateMessage(
            message:
                'No videos yet. Upload a swim video to start AI analysis.',
          )
        else
          ...widget.data.videos.map(
            (video) => _VideoCard(
              video: video,
              analysis: widget.data.analysisForVideo(video.id),
              dateFormat: dateFormat,
              analyzing: _analyzing,
              onAnalyze: () => _runAnalysis(video),
            ),
          ),
      ],
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
  });

  final SwimVideo video;
  final SwimVideoAnalysis? analysis;
  final DateFormat dateFormat;
  final bool analyzing;
  final VoidCallback onAnalyze;

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
              FilledButton.tonal(
                onPressed: widget.analyzing ? null : widget.onAnalyze,
                child: widget.analyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Run AI Swim Analysis'),
              )
            else ...[
              const SizedBox(height: 8),
              Text('AI Score: ${widget.analysis!.overallScore}/100',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(widget.analysis!.summary),
              const SizedBox(height: 6),
              Text('Strengths: ${widget.analysis!.strengths}'),
              Text('Improve: ${widget.analysis!.improvements}'),
            ],
          ],
        ),
      ),
    );
  }
}
