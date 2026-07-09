import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../core/recruiting/recruiting_business_card_pdf.dart';
import '../core/theme/app_theme.dart';

class RecruitingCardSnapshot {
  const RecruitingCardSnapshot({
    required this.displayName,
    required this.swimIqScore,
    required this.highestCut,
    required this.team,
    required this.gpa,
    required this.website,
    required this.topEvents,
    required this.graduationYear,
    required this.usaSwimmingId,
    required this.fileSafeName,
  });

  final String displayName;
  final int swimIqScore;
  final String highestCut;
  final String? team;
  final String? gpa;
  final String? website;
  final List<String> topEvents;
  final int? graduationYear;
  final String? usaSwimmingId;
  final String fileSafeName;
}

class RecruitingCardExportBar extends StatelessWidget {
  const RecruitingCardExportBar({
    super.key,
    required this.snapshot,
  });

  final RecruitingCardSnapshot snapshot;

  Future<Uint8List> _pdfBytes() async {
    final bytes = await RecruitingBusinessCardPdf.buildBytes(
      displayName: snapshot.displayName,
      swimIqScore: snapshot.swimIqScore,
      highestCut: snapshot.highestCut,
      team: snapshot.team,
      gpa: snapshot.gpa,
      website: snapshot.website,
      topEvents: snapshot.topEvents,
      graduationYear: snapshot.graduationYear,
      usaSwimmingId: snapshot.usaSwimmingId,
    );
    return Uint8List.fromList(bytes);
  }

  Future<void> _exportPdf(BuildContext context) async {
    try {
      final bytes = await _pdfBytes();
      if (!context.mounted) return;
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'SwimIQ_Recruiting_Card_${snapshot.fileSafeName}.pdf',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recruiting card PDF ready — save or share.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export recruiting card: $error')),
      );
    }
  }

  Future<void> _printCard(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => _pdfBytes(),
        name: 'SwimIQ_Recruiting_Card',
        format: RecruitingBusinessCardPdf.pageFormat,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open print preview: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recruiting Card',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportPdf(context),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Export PDF'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _printCard(context),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Print'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Wallet-sized card (3.5″ × 2″) — print for meets, mail to coaches, or save as PDF.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
                height: 1.3,
              ),
        ),
      ],
    );
  }
}
