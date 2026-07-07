import 'package:flutter/material.dart';

import '../core/services/video_analysis_presenter.dart';
import '../core/theme/app_theme.dart';
import '../data/models/swim_video_analysis.dart';

class VideoAnalysisReport extends StatefulWidget {
  const VideoAnalysisReport({
    super.key,
    required this.analysis,
    required this.onCoachNotesChanged,
  });

  final SwimVideoAnalysis analysis;
  final ValueChanged<String> onCoachNotesChanged;

  @override
  State<VideoAnalysisReport> createState() => _VideoAnalysisReportState();
}

class _VideoAnalysisReportState extends State<VideoAnalysisReport> {
  late final TextEditingController _coachNotesController;

  @override
  void initState() {
    super.initState();
    _coachNotesController = TextEditingController(
      text: VideoAnalysisPresenter.coachNotes(widget.analysis),
    );
  }

  @override
  void didUpdateWidget(covariant VideoAnalysisReport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.analysis.id != widget.analysis.id) {
      _coachNotesController.text =
          VideoAnalysisPresenter.coachNotes(widget.analysis);
    }
  }

  @override
  void dispose() {
    _coachNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = VideoAnalysisPresenter.visibleSections(widget.analysis);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScoreStrip(analysis: widget.analysis),
        const SizedBox(height: 12),
        if (widget.analysis.disclaimer != null)
          Text(
            widget.analysis.disclaimer!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
          ),
        const SizedBox(height: 12),
        for (final entry in sections.entries)
          if (entry.key != 'Coach notes for next race')
            _SectionCard(title: entry.key, body: entry.value),
        _CoachNotesEditor(
          controller: _coachNotesController,
          onSave: () => widget.onCoachNotesChanged(_coachNotesController.text),
        ),
        if (widget.analysis.poseMetrics != null) ...[
          const SizedBox(height: 8),
          _SectionCard(
            title: 'Body mechanics (MediaPipe)',
            body: widget.analysis.poseMetrics!.observations
                .map((line) => '• $line')
                .join('\n'),
          ),
        ],
      ],
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({required this.analysis});

  final SwimVideoAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ScoreChip(label: 'Overall', value: analysis.overallScore),
        _ScoreChip(label: 'Technique', value: analysis.techniqueScore),
        _ScoreChip(label: 'Pace', value: analysis.paceScore),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                ),
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(height: 1.45)),
        ],
      ),
    );
  }
}

class _CoachNotesEditor extends StatelessWidget {
  const _CoachNotesEditor({
    required this.controller,
    required this.onSave,
  });

  final TextEditingController controller;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Coach notes for next race',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Coach: add race-day cues, warm-up plan, mindset…',
              filled: true,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: onSave,
              child: const Text('Save coach notes'),
            ),
          ),
        ],
      ),
    );
  }
}
