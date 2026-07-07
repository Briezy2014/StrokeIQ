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
    final pro = sections['Quick pro from this video'];
    final con = sections['Quick con from this video'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScoreStrip(analysis: widget.analysis),
        const SizedBox(height: 12),
        if (pro != null || con != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pro != null)
                Expanded(
                  child: _InsightCard(
                    title: 'Quick pro',
                    body: pro,
                    icon: Icons.thumb_up_alt_outlined,
                    accent: const Color(0xFF16A34A),
                  ),
                ),
              if (pro != null && con != null) const SizedBox(width: 10),
              if (con != null)
                Expanded(
                  child: _InsightCard(
                    title: 'Quick con',
                    body: con,
                    icon: Icons.trending_down,
                    accent: const Color(0xFFEA580C),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
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
          if (entry.key != 'Coach notes for next race' &&
              entry.key != 'Quick pro from this video' &&
              entry.key != 'Quick con from this video')
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
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDeep,
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: accent.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(height: 1.45)),
        ],
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.surfaceLight,
          ],
        ),
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
          const SizedBox(height: 4),
          Text(
            'Editable — add race-day cues your coach wants on deck.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
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
