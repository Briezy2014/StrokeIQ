import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/services/usa_motivational_standards_catalog.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/motivational_cut.dart';
import '../data/models/personal_best_entry.dart';
import '../data/models/race_log.dart';
import '../data/models/swimmer_profile.dart';

/// Dashboard pie — USA cuts mix (Pro) or stroke mix (training logs).
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
    'A': Color(0xFF94A3B8),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showProFeatures && personalBests.isNotEmpty
              ? 'Cuts mix'
              : 'Training mix',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDeep,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 132,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                    sections: slices
                        .map(
                          (slice) => PieChartSectionData(
                            value: slice.value.toDouble(),
                            color: slice.color,
                            title: '${slice.value}',
                            radius: 44,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final slice in slices.take(4))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: slice.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${slice.label} (${slice.value})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      '$total events',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.showProFeatures});

  final bool showProFeatures;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showProFeatures ? 'Cuts mix' : 'Training mix',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDeep,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 132,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              showProFeatures
                  ? 'Log official meet times to see your USA cuts breakdown.'
                  : 'Log training sessions to see your stroke mix.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                height: 1.35,
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
