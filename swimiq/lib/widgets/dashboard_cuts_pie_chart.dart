import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/services/usa_motivational_standards_catalog.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/motivational_cut.dart';
import '../data/models/personal_best_entry.dart';
import '../data/models/race_log.dart';
import '../data/models/swimmer_profile.dart';

/// Featured pie — USA cuts mix (Pro) or stroke mix (training logs).
class DashboardCutsPieChart extends StatelessWidget {
  const DashboardCutsPieChart({
    super.key,
    required this.personalBests,
    required this.raceLogs,
    required this.catalog,
    required this.profile,
    required this.showProFeatures,
    this.title,
    this.subtitle,
    this.emptyMessage,
    this.showCutBars = false,
  });

  final List<PersonalBestEntry> personalBests;
  final List<RaceLog> raceLogs;
  final UsaMotivationalStandardsCatalog catalog;
  final SwimmerProfile? profile;
  final bool showProFeatures;

  /// Optional overrides (PBs tab uses friendlier copy).
  final String? title;
  final String? subtitle;
  final String? emptyMessage;

  /// When true, also shows a horizontal bar breakdown under the pie.
  final bool showCutBars;

  static const cutColors = <String, Color>{
    'AAAA': Color(0xFF7C3AED),
    'AAA': Color(0xFFF59E0B),
    'AA': Color(0xFFEAB308),
    'A': AppColors.primary,
    'BB': Color(0xFFCD7F32),
    'B': Color(0xFF64748B),
    'Below B': Color(0xFFCBD5E1),
  };

  /// Public color lookup for cut badges on PB cards.
  static Color colorForCut(String cut) =>
      cutColors[cut] ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final slices = showProFeatures && personalBests.isNotEmpty
        ? _cutSlices()
        : _strokeSlices();

    final isCuts = showProFeatures && personalBests.isNotEmpty;
    final heading = title ?? (isCuts ? 'Cuts mix' : 'Training mix');
    final support = subtitle ??
        (isCuts
            ? 'USA motivational cuts across your best times.'
            : 'Stroke mix from your recent training logs.');

    if (slices.isEmpty) {
      return _EmptyChart(
        title: heading,
        subtitle: support,
        message: emptyMessage ??
            (showProFeatures
                ? 'Add official meet times on the Log tab to see your USA cuts breakdown.'
                : 'Log training sessions to see your stroke mix.'),
      );
    }

    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          heading,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDeep,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          support,
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
        if (showCutBars && isCuts) ...[
          const SizedBox(height: 18),
          ...slices.map(
            (slice) => _CutBarRow(
              label: slice.label,
              count: slice.value,
              total: total,
              color: slice.color,
            ),
          ),
        ],
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

    // Stable ladder order so the chart reads like standards, not random.
    const ladder = ['AAAA', 'AAA', 'AA', 'A', 'BB', 'B', 'Below B'];
    final ordered = <_PieSlice>[];
    for (final level in ladder) {
      final count = counts.remove(level);
      if (count == null || count <= 0) continue;
      ordered.add(_PieSlice(level, count, cutColors[level]!));
    }
    for (final entry in counts.entries) {
      ordered.add(
        _PieSlice(
          entry.key,
          entry.value,
          cutColors[entry.key] ?? AppColors.primary,
        ),
      );
    }
    return ordered;
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

class _CutBarRow extends StatelessWidget {
  const _CutBarRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 12,
                backgroundColor: color.withValues(alpha: 0.12),
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
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
  const _EmptyChart({
    required this.title,
    required this.subtitle,
    required this.message,
  });

  final String title;
  final String subtitle;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDeep,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
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
              message,
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

/// Shared card wrapper for Dashboard + PBs cuts visuals.
class CutsMixCard extends StatelessWidget {
  const CutsMixCard({
    super.key,
    required this.personalBests,
    required this.raceLogs,
    required this.catalog,
    required this.profile,
    required this.showProFeatures,
    this.title,
    this.subtitle,
    this.emptyMessage,
    this.showCutBars = false,
  });

  final List<PersonalBestEntry> personalBests;
  final List<RaceLog> raceLogs;
  final UsaMotivationalStandardsCatalog catalog;
  final SwimmerProfile? profile;
  final bool showProFeatures;
  final String? title;
  final String? subtitle;
  final String? emptyMessage;
  final bool showCutBars;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: DashboardCutsPieChart(
          personalBests: personalBests,
          raceLogs: raceLogs,
          catalog: catalog,
          profile: profile,
          showProFeatures: showProFeatures,
          title: title,
          subtitle: subtitle,
          emptyMessage: emptyMessage,
          showCutBars: showCutBars,
        ),
      ),
    );
  }
}
