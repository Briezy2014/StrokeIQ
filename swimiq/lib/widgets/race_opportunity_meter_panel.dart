import 'package:flutter/material.dart';

import '../core/coaching/race_opportunity_meter.dart';
import '../core/theme/app_theme.dart';
import '../data/models/video_engine_v2/analysis_results.dart';

/// Opportunity Meter / Race Scan — where time can still be found.
class RaceOpportunityMeterPanel extends StatelessWidget {
  const RaceOpportunityMeterPanel({
    super.key,
    required this.report,
    required this.stroke,
    this.results,
    this.distanceM,
  });

  final AnalysisReport report;
  final String stroke;
  final AnalysisResults? results;
  final int? distanceM;

  @override
  Widget build(BuildContext context) {
    final meter = RaceOpportunityMeterBuilder.fromReport(
      report: report,
      stroke: stroke,
      distanceM: distanceM,
      results: results,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF041526),
            Color(0xFF0B3D6E),
            AppColors.primaryDeep,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'RACE SCAN',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  meter.modeBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Where time can still be found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            meter.caption,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Potential drop',
                  value: meter.potentialLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Overall Race IQ',
                  value: '${meter.raceIq}',
                  emphasize: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (meter.raceIq / 100).clamp(0.35, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent,
                      Colors.white.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final segment in meter.segments) ...[
            _SegmentRow(
              segment: segment,
              onTap: () => _openDetail(context, segment, meter),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 2),
          Text(
            'Tap a row for what happened, next race, and drills.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    OpportunitySegment segment,
    RaceOpportunityMeter meter,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _SignalDot(signal: segment.signal, large: true),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        segment.label,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDark,
                            ),
                      ),
                    ),
                    Text(
                      segment.opportunityLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDeep,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _signalCopy(segment.signal),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                _DetailBlock(
                  title: 'What happened',
                  body: segment.whatHappened,
                ),
                const SizedBox(height: 12),
                _DetailBlock(
                  title: 'Next race',
                  body: segment.nextRaceCue,
                ),
                if (segment.swimDrills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailBlock(
                    title: 'Swim practice',
                    bullets: segment.swimDrills,
                  ),
                ],
                if (segment.drylandDrills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailBlock(
                    title: 'Dryland',
                    bullets: segment.drylandDrills,
                  ),
                ],
                if (meter.hasPotential) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'Full-race potential from this scan: ${meter.potentialLabel}.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                            color: AppColors.primaryDark,
                          ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  static String _signalCopy(OpportunitySignal signal) {
    switch (signal) {
      case OpportunitySignal.lockedIn:
        return 'Green — keep this automatic.';
      case OpportunitySignal.watch:
        return 'Yellow — worth a race focus.';
      case OpportunitySignal.opportunity:
        return 'Red — biggest time still on the table.';
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: emphasize ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: emphasize ? 28 : 18,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({
    required this.segment,
    required this.onTap,
  });

  final OpportunitySegment segment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _SignalDot(signal: segment.signal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  segment.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                segment.opportunityLabel,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: segment.signal == OpportunitySignal.lockedIn
                        ? 0.65
                        : 0.95,
                  ),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalDot extends StatelessWidget {
  const _SignalDot({
    required this.signal,
    this.large = false,
  });

  final OpportunitySignal signal;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final color = switch (signal) {
      OpportunitySignal.lockedIn => const Color(0xFF22C55E),
      OpportunitySignal.watch => const Color(0xFFFBBF24),
      OpportunitySignal.opportunity => const Color(0xFFEF4444),
    };
    final size = large ? 16.0 : 12.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.title,
    this.body,
    this.bullets = const [],
  });

  final String title;
  final String? body;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          if (body != null)
            Text(
              body!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          for (final bullet in bullets) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
