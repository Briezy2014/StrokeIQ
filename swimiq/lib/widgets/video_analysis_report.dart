import 'package:flutter/material.dart';

import '../core/services/gemini_swim_analysis_service.dart';
import '../core/services/video_analysis_presenter.dart';
import '../core/services/video_analysis_scores.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/youth_friendly_analysis.dart';
import '../data/models/swim_pose_metrics.dart';
import '../data/models/swim_video_analysis.dart';

class VideoAnalysisReport extends StatefulWidget {
  const VideoAnalysisReport({
    super.key,
    required this.analysis,
    required this.onCoachNotesChanged,
    this.serverHealth,
  });

  final SwimVideoAnalysis analysis;
  final ValueChanged<String> onCoachNotesChanged;
  final VideoAnalysisServerHealth? serverHealth;

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
    final pro = sections['Quick pro from this video'] ??
        widget.analysis.analysisJson?['quick_pro']?.toString();
    final con = sections['Quick con from this video'] ??
        widget.analysis.analysisJson?['quick_con']?.toString();
    final engineLabel = VideoAnalysisPresenter.analysisEngineLabel(widget.analysis);
    final disclaimer = VideoAnalysisPresenter.friendlyDisclaimer(widget.analysis);
    final health = widget.serverHealth;
    final readyBanner = VideoAnalysisScores.serverReadyBanner(health);
    final fallbackReason = VideoAnalysisScores.fallbackReason(
      widget.analysis,
      serverHealth: health,
    );
    final technicalError = VideoAnalysisScores.technicalError(
      widget.analysis,
      serverHealth: health,
    );
    final pipelineNote = VideoAnalysisScores.pipelineNote(
      widget.analysis,
      serverHealth: health,
    );
    final awaitingGemini = VideoAnalysisScores.awaitingGeminiVideoRead(
      widget.analysis,
      serverHealth: health,
    );
    final showDeploySteps = awaitingGemini &&
        !VideoAnalysisScores.serverIsStreamReady(health);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScoreStrip(analysis: widget.analysis, serverHealth: health),
        const SizedBox(height: 12),
        if (readyBanner != null) ...[
          _ServerReadyBanner(message: readyBanner),
          const SizedBox(height: 8),
        ],
        if (fallbackReason != null) ...[
          _FallbackBanner(message: fallbackReason),
          if (technicalError != null) ...[
            const SizedBox(height: 8),
            _TechnicalErrorBanner(error: technicalError),
          ],
          const SizedBox(height: 8),
        ],
        if (pipelineNote != null) ...[
          Text(
            pipelineNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 12),
        ] else if (fallbackReason != null)
          const SizedBox(height: 4),
        if (showDeploySteps) ...[
          _DeployStepsCard(body: VideoAnalysisScores.deployStepsBody),
          const SizedBox(height: 12),
        ] else if (engineLabel != null) ...[
          Text(
            engineLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
          ),
          const SizedBox(height: 8),
        ],
        if (!awaitingGemini && (pro != null || con != null)) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pro != null)
                Expanded(
                  child: _InsightCard(
                    title: VideoAnalysisPresenter.strengthInsightTitle,
                    body: pro,
                    icon: Icons.thumb_up_alt_outlined,
                    accent: const Color(0xFF16A34A),
                  ),
                ),
              if (pro != null && con != null) const SizedBox(width: 10),
              if (con != null)
                Expanded(
                  child: _InsightCard(
                    title: VideoAnalysisPresenter.workOnInsightTitle,
                    body: con,
                    icon: Icons.trending_down,
                    accent: const Color(0xFFEA580C),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (disclaimer != null)
          Text(
            '$disclaimer\n${YouthFriendlyAnalysis.audienceNote}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
          ),
        if (widget.analysis.poseMetrics != null) ...[
          const SizedBox(height: 12),
          _MediaPipeBodyMechanicsCard(metrics: widget.analysis.poseMetrics!),
        ],
        const SizedBox(height: 12),
        if (!awaitingGemini)
          for (final entry in sections.entries)
            if (entry.key != 'Coach notes for next race' &&
                entry.key != 'Quick pro from this video' &&
                entry.key != 'Quick con from this video')
              _SectionCard(title: entry.key, body: entry.value),
        _CoachNotesEditor(
          controller: _coachNotesController,
          onSave: () => widget.onCoachNotesChanged(_coachNotesController.text),
        ),
      ],
    );
  }
}

class _MediaPipeBodyMechanicsCard extends StatelessWidget {
  const _MediaPipeBodyMechanicsCard({required this.metrics});

  final SwimPoseMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final pro = metrics.bodyMechanicsPro;
    final con = metrics.bodyMechanicsCon;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MediaPipe body mechanics',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Automated angle read from your video — hips up, head down, body line, elbow, and kick. '
            'Read with your coach; not medical advice.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
          ),
          if (pro != null || con != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pro != null)
                  Expanded(
                    child: _InsightCard(
                      title: VideoAnalysisPresenter.bodyStrengthInsightTitle,
                      body: pro,
                      icon: Icons.check_circle_outline,
                      accent: const Color(0xFF16A34A),
                    ),
                  ),
                if (pro != null && con != null) const SizedBox(width: 10),
                if (con != null)
                  Expanded(
                    child: _InsightCard(
                      title: VideoAnalysisPresenter.bodyWorkOnInsightTitle,
                      body: con,
                      icon: Icons.build_outlined,
                      accent: const Color(0xFFEA580C),
                    ),
                  ),
              ],
            ),
          ],
          if (metrics.bodyMechanicsSuggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Suggestions',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
            ),
            const SizedBox(height: 6),
            for (final suggestion in metrics.bodyMechanicsSuggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $suggestion', style: const TextStyle(height: 1.45)),
              ),
          ],
          const SizedBox(height: 10),
          Text(
            'Angle snapshot',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            metrics.observations.map((line) => '• $line').join('\n'),
            style: const TextStyle(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({
    required this.analysis,
    this.serverHealth,
  });

  final SwimVideoAnalysis analysis;
  final VideoAnalysisServerHealth? serverHealth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
          Row(
            children: [
              Text(
                'AI coach ratings',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeep,
                    ),
              ),
              const Spacer(),
              Text(
                'out of ${VideoAnalysisScores.maxScore}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            VideoAnalysisScores.legendFor(
              analysis,
              serverHealth: serverHealth,
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 520;
              final children = [
                _ScoreTile(
                  analysis: analysis,
                  serverHealth: serverHealth,
                  title: VideoAnalysisScores.overallTitle,
                  value: analysis.overallScore,
                  hint: VideoAnalysisScores.overallSummary(
                    analysis,
                    serverHealth: serverHealth,
                  ),
                ),
                _ScoreTile(
                  analysis: analysis,
                  serverHealth: serverHealth,
                  title: VideoAnalysisScores.techniqueTitle,
                  value: analysis.techniqueScore,
                  hint: VideoAnalysisScores.techniqueSummary(
                    analysis,
                    serverHealth: serverHealth,
                  ),
                ),
                _ScoreTile(
                  analysis: analysis,
                  serverHealth: serverHealth,
                  title: VideoAnalysisScores.paceTitle,
                  value: analysis.paceScore,
                  hint: VideoAnalysisScores.paceSummary(
                    analysis,
                    serverHealth: serverHealth,
                  ),
                ),
              ];
              if (wide) {
                return Row(
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: children[i]),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    children[i],
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.analysis,
    required this.title,
    required this.value,
    required this.hint,
    this.serverHealth,
  });

  final SwimVideoAnalysis analysis;
  final String title;
  final int value;
  final String hint;
  final VideoAnalysisServerHealth? serverHealth;

  @override
  Widget build(BuildContext context) {
    final color = VideoAnalysisScores.scoreColor(
      analysis,
      value,
      serverHealth: serverHealth,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.14),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            VideoAnalysisScores.formatScore(
              analysis,
              value,
              serverHealth: serverHealth,
            ),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDeep,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            softWrap: true,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeployStepsCard extends StatelessWidget {
  const _DeployStepsCard({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build_circle_outlined, color: AppColors.primaryDeep),
              const SizedBox(width: 8),
              Text(
                'Fix video analysis (4 steps)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeep,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.45,
                  color: Colors.grey.shade800,
                ),
          ),
        ],
      ),
    );
  }
}

class _TechnicalErrorBanner extends StatelessWidget {
  const _TechnicalErrorBanner({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Technical error (send this to support)',
            style: TextStyle(
              color: Colors.grey.shade900,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            error,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
              height: 1.35,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerReadyBanner extends StatelessWidget {
  const _ServerReadyBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade900,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackBanner extends StatelessWidget {
  const _FallbackBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
                height: 1.35,
                fontSize: 12,
              ),
            ),
          ),
        ],
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
            'Your AI coach — race-day steps with real swim words (streamline, take your marks, breakout). '
            'Tweak if your deck coach adds cues.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'AI coach notes appear here — edit to personalize…',
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
