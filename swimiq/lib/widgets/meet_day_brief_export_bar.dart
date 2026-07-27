import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../core/recruiting/meet_day_brief_pdf.dart';
import '../core/services/race_intelligence_service.dart';
import '../core/theme/app_theme.dart';

class MeetDayBriefExportBar extends StatelessWidget {
  const MeetDayBriefExportBar({
    super.key,
    required this.plan,
    required this.athleteName,
    required this.fileSafeName,
  });

  final RaceIntelligencePlan plan;
  final String athleteName;
  final String fileSafeName;

  Future<Uint8List> _bytes() async {
    final pdf = await MeetDayBriefPdf.buildBytes(
      plan: plan,
      athleteName: athleteName,
    );
    return Uint8List.fromList(pdf);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Meet-Day Brief PDF',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'One-page warm-up, nutrition, checklist, and timeline for the next meet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final bytes = await _bytes();
                      if (!context.mounted) return;
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename: 'SwimIQ_Meet_Day_Brief_$fileSafeName.pdf',
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not export brief: $error')),
                      );
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Export PDF'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    try {
                      await Printing.layoutPdf(
                        onLayout: (_) => _bytes(),
                        name: 'SwimIQ_Meet_Day_Brief',
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not print: $error')),
                      );
                    }
                  },
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Print'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
