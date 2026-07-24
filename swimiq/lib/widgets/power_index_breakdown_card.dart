import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/recruiting/power_index.dart';
import '../core/theme/app_theme.dart';

/// Explains how Power Index is built — formula pie + plain-language meanings.
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
            'How Power Index is calculated',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            power.hasEnoughData
                ? 'Each pie slice is a weighted part of the score. Read what '
                    'each section means below — especially College fit, which '
                    'is about recruiting time ranges, not offers.'
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
              final wide = constraints.maxWidth >= 560;
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
                    const SizedBox(height: 10),
                  ],
                ],
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: chart),
                    const SizedBox(width: 16),
                    Expanded(flex: 7, child: legend),
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

  static List<PowerIndexFactor> _placeholderFactors() => [
        for (final entry in PowerIndexFactor.explanations.entries)
          PowerIndexFactor(
            id: entry.key,
            label: _labelFor(entry.key),
            weightPercent: _weightFor(entry.key),
            componentScore: 0,
            weightedPoints: 0,
            explanation: entry.value,
          ),
      ];

  static String _labelFor(String id) {
    switch (id) {
      case 'cuts':
        return 'USA cuts / speed';
      case 'depth':
        return 'Event depth';
      case 'progression':
        return 'Meet progression';
      case 'college':
        return 'College fit';
      case 'technique':
        return 'Video technique';
      default:
        return id;
    }
  }

  static int _weightFor(String id) {
    switch (id) {
      case 'cuts':
        return PowerIndex.weightCuts;
      case 'depth':
        return PowerIndex.weightDepth;
      case 'progression':
        return PowerIndex.weightProgression;
      case 'college':
        return PowerIndex.weightCollege;
      case 'technique':
        return PowerIndex.weightTechnique;
      default:
        return 0;
    }
  }
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
    final scoreLine = showScores
        ? '${factor.weightPercent}% of formula · score ${factor.componentScore} → '
            '+${factor.weightedPoints.toStringAsFixed(1)} pts'
        : '${factor.weightPercent}% of formula';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
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
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scoreLine,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  factor.explanation,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
