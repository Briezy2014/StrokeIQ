import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/services/usa_motivational_standards_catalog.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/motivational_cut.dart';
import '../data/models/personal_best_entry.dart';
import '../data/models/race_log.dart';
import '../data/models/swimmer_profile.dart';

/// Featured dashboard pie — USA cuts mix (Pro) or stroke mix (training logs).
class DashboardCutsPieChart extends StatelessWidget {
  const DashboardCutsPieChart({
    super.key,
    required this.personalBests,
    required this.raceLogs,
    required this.catalog,
    required this.profile,
    required this.showProFeatures,
  });

  final List<PersonalBestEntry> personalBests;
  final List<RaceLog> raceLogs;
  final UsaMotivationalStandardsCatalog catalog;
  final SwimmerProfile? profile;
  final bool showProFeatures;

  static const _cutColors = <String, Color>{
    'AAAA': Color(0xFF7C3AED),
    'AAA': Color(0xFFF59E0B),
    'AA': Color(0xFFEAB308),
    'A': AppColors.primary,
    'BB': Color(0xFFCD7F32),
    'B': Color(0xFF64748B),
    'Below B': Color(0xFFCBD5E1),
  };

  @override
  Widget build(BuildContext context) {
    final slices = showProFeatures && personalBests.isNotEmpty
        ? _cutSlices()
        : _strokeSlices();

    if (slices.isEmpty) {
      return _EmptyChart(showProFeatures: showProFeatures);
    }

    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    final isCuts = showProFeatures && personalBests.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isCuts ? 'Cuts mix' : 'Training mix',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDeep,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          isCuts
              ? 'USA motivational cuts across your best times.'
              : 'Stroke mix from your recent training logs.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 58,
                  startDegreeOffset: -90,
                  sections: slices
                      .map(
                        (slice) => PieChartSectionData(
                          value: slice.value.toDouble(),
                          color: slice.color,
                          title: '${slice.value}',
                          radius: 72,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeep,
                      height: 1,
                    ),
                  ),
                  Text(
                    isCuts ? 'events' : 'logs',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final slice in slices)
              _LegendChip(
                color: slice.color,
                label: '${slice.label} · ${slice.value}',
              ),
          ],
        ),
      ],
    );
  }

  List<_PieSlice> _cutSlices() {
    final counts = <String, int>{};
    for (final pb in personalBests) {
      final cut = MotivationalCut.labelForSwim(
        catalog: catalog,
        profile: profile,
        stroke: pb.stroke,
        distance: pb.distance,
        course: pb.course,
        timeSeconds: pb.timeSeconds,
      );
      counts[cut] = (counts[cut] ?? 0) + 1;
    }

    return counts.entries
        .map(
          (entry) => _PieSlice(
            entry.key,
            entry.value,
            _cutColors[entry.key] ?? AppColors.primary,
          ),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<_PieSlice> _strokeSlices() {
    final counts = <String, int>{};
    for (final log in raceLogs) {
      final stroke = log.stroke.trim().isEmpty ? 'Other' : log.stroke;
      counts[stroke] = (counts[stroke] ?? 0) + 1;
    }

    const strokeColors = [
      AppColors.primary,
      AppColors.accent,
      Color(0xFF22C55E),
      Color(0xFFF97316),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
    ];

    var colorIndex = 0;
    return counts.entries
        .map((entry) {
          final slice = _PieSlice(
            entry.key,
            entry.value,
            strokeColors[colorIndex % strokeColors.length],
          );
          colorIndex++;
          return slice;
        })
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.textDark.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.showProFeatures});

  final bool showProFeatures;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          showProFeatures ? 'Cuts mix' : 'Training mix',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDeep,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          showProFeatures
              ? 'USA motivational cuts across your best times.'
              : 'Stroke mix from your recent training logs.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 18),
        Container(
          height: 220,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              showProFeatures
                  ? 'Add official meet times on the Log tab to see your USA cuts breakdown.'
                  : 'Log training sessions to see your stroke mix.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PieSlice {
  const _PieSlice(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}
