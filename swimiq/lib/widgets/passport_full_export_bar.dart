import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../core/recruiting/athlete_passport_pdf.dart';
import '../core/utils/passport_metrics.dart';
import '../data/models/swimmer_profile.dart';

/// Export / print the full Athlete Passport (not just the wallet card).
class PassportFullExportBar extends StatelessWidget {
  const PassportFullExportBar({
    super.key,
    required this.snapshot,
    required this.profile,
    required this.displayName,
    required this.fileSafeName,
    this.showHeader = true,
  });

  final PassportSnapshot snapshot;
  final SwimmerProfile? profile;
  final String displayName;
  final String fileSafeName;

  /// When false, only the action buttons are shown (parent supplies titles).
  final bool showHeader;

  Future<Uint8List> _pdfBytes() async {
    final bytes = await AthletePassportPdf.buildBytes(
      snapshot: snapshot,
      profile: profile,
      displayName: displayName,
    );
    return Uint8List.fromList(bytes);
  }

  Future<void> _exportPdf(BuildContext context) async {
    try {
      final bytes = await _pdfBytes();
      if (!context.mounted) return;
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'SwimIQ_Athlete_Passport_$fileSafeName.pdf',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full Athlete Passport PDF ready — save or share.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export passport: $error')),
      );
    }
  }

  Future<void> _printPdf(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => _pdfBytes(),
        name: 'SwimIQ_Athlete_Passport',
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
    final actions = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final export = OutlinedButton.icon(
          onPressed: () => _exportPdf(context),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: Text(compact ? 'PDF' : 'Export PDF'),
        );
        final printBtn = FilledButton.icon(
          onPressed: () => _printPdf(context),
          icon: const Icon(Icons.print_outlined, size: 18),
          label: const Text('Print'),
        );
        if (compact) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [export, printBtn],
          );
        }
        return Row(
          children: [
            Expanded(child: export),
            const SizedBox(width: 8),
            Expanded(child: printBtn),
          ],
        );
      },
    );

    if (!showHeader) return actions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Full passport packet',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'Multi-page PDF for coaches and recruiting.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
                height: 1.3,
              ),
        ),
        const SizedBox(height: 10),
        actions,
      ],
    );
  }
}
