import 'package:flutter/material.dart';

import '../core/recruiting/cut_to_college_service.dart';
import '../core/services/college_recruiting_benchmark_catalog.dart';
import '../core/theme/app_theme.dart';
import '../providers/swimmer_data_provider.dart';

/// “X seconds from AA / target school” timeline.
class CutToCollegeTimelineCard extends StatefulWidget {
  const CutToCollegeTimelineCard({super.key, required this.data});

  final SwimmerData data;

  @override
  State<CutToCollegeTimelineCard> createState() =>
      _CutToCollegeTimelineCardState();
}

class _CutToCollegeTimelineCardState extends State<CutToCollegeTimelineCard> {
  CutToCollegeTimeline? _timeline;
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CutToCollegeTimelineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      CollegeRecruitingBenchmarkCatalog? catalog;
      try {
        catalog = await CollegeRecruitingBenchmarkCatalog.loadFromAssets();
      } catch (_) {
        catalog = null;
      }
      final timeline = CutToCollegeService.build(
        data: widget.data,
        collegeCatalog: catalog,
      );
      if (!mounted) return;
      setState(() {
        _timeline = timeline;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cut-to-College timeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Seconds to the next USA cut and target-school recruiting window. '
            'College lines compare your official PB to that event’s recruit window '
            '(your time is shown).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_error != null)
            Text('Could not build timeline: $_error')
          else if (_timeline == null || _timeline!.steps.isEmpty)
            Text(_timeline?.summary ?? 'Add official PBs to start the timeline.')
          else ...[
            for (final step in _timeline!.steps) ...[
              _StepTile(step: step),
              const SizedBox(height: 8),
            ],
            Text(
              _timeline!.summary,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step});

  final CutToCollegeStep step;

  @override
  Widget build(BuildContext context) {
    final met = step.isMet;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: met
            ? const Color(0xFFECFDF5)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: met
              ? const Color(0xFF6EE7B7)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.flag_outlined,
            color: met ? const Color(0xFF059669) : AppColors.primaryDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  step.detail,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
          Text(
            step.gapLabel,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: met ? const Color(0xFF059669) : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
