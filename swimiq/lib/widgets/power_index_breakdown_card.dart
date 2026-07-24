import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/recruiting/power_index.dart';
import '../core/theme/app_theme.dart';

/// Explains how Power Index is built — formula pie + current factor scores.
class PowerIndexBreakdownCard extends StatelessWidget {
  const PowerIndexBreakdownCard({
    super.key,
    required this.powerIndex,
  });

  final PowerIndexSnapshot powerIndex;

  static const _factorColors = <String, Color>{
    'cuts': Color(0xFF0B5CAD),
    'depth': Color(0xFF009CFF),
    'progression': Color(0xFF38B6FF),
    'college': Color(0xFF0EA5E9),
    'technique': Color(0xFF64748B),
  };

  @override
  Widget build(BuildContext context) {
    final power = powerIndex;
    final factors = power.hasEnoughData && power.factors.isNotEmpty
        ? power.factors
        : _placeholderFactors();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Power Index breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            power.hasEnoughData
                ? 'Weighted mix of USA cuts, event depth, meet progression, '
                    'college fit, and video technique.'
                : (power.missingDataHint ??
                    'Add official PBs plus birthday and gender to calculate '
                        'Power Index.'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 520;
              final chart = SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 52,
                        startDegreeOffset: -90,
                        sections: factors
                            .map(
                              (factor) => PieChartSectionData(
                                value: factor.weightPercent.toDouble(),
                                color: _colorFor(factor.id),
                                title: '${factor.weightPercent}%',
                                radius: 64,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
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
                          power.hasEnoughData ? '${power.score}' : '—',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDeep,
                            height: 1,
                          ),
                        ),
                        Text(
                          power.hasEnoughData ? power.label : 'Not ready',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final legend = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final factor in factors) ...[
                    _FactorLegendRow(
                      color: _colorFor(factor.id),
                      factor: factor,
                      showScores: power.hasEnoughData,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: chart),
                    const SizedBox(width: 16),
                    Expanded(child: legend),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  chart,
                  const SizedBox(height: 8),
                  legend,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static Color _colorFor(String id) =>
      _factorColors[id] ?? AppColors.primary;

  static List<PowerIndexFactor> _placeholderFactors() => const [
        PowerIndexFactor(
          id: 'cuts',
          label: 'USA cuts / speed',
          weightPercent: PowerIndex.weightCuts,
          componentScore: 0,
          weightedPoints: 0,
        ),
        PowerIndexFactor(
          id: 'depth',
          label: 'Event depth',
          weightPercent: PowerIndex.weightDepth,
          componentScore: 0,
          weightedPoints: 0,
        ),
        PowerIndexFactor(
          id: 'progression',
          label: 'Meet progression',
          weightPercent: PowerIndex.weightProgression,
          componentScore: 0,
          weightedPoints: 0,
        ),
        PowerIndexFactor(
          id: 'college',
          label: 'College fit',
          weightPercent: PowerIndex.weightCollege,
          componentScore: 0,
          weightedPoints: 0,
        ),
        PowerIndexFactor(
          id: 'technique',
          label: 'Video technique',
          weightPercent: PowerIndex.weightTechnique,
          componentScore: 0,
          weightedPoints: 0,
        ),
      ];
}

class _FactorLegendRow extends StatelessWidget {
  const _FactorLegendRow({
    required this.color,
    required this.factor,
    required this.showScores,
  });

  final Color color;
  final PowerIndexFactor factor;
  final bool showScores;

  @override
  Widget build(BuildContext context) {
    final detail = showScores
        ? '${factor.weightPercent}% · score ${factor.componentScore} → '
            '+${factor.weightedPoints.toStringAsFixed(1)}'
        : '${factor.weightPercent}% of formula';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                factor.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
