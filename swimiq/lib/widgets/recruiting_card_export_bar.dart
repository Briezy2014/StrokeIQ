import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

import '../core/recruiting/recruiting_business_card_pdf.dart';

class RecruitingCardSnapshot {
  const RecruitingCardSnapshot({
    required this.displayName,
    required this.swimIqScore,
    required this.highestCut,
    required this.team,
    required this.topEvents,
    required this.graduationYear,
    required this.fileSafeName,
    this.gpa,
    this.website,
    this.email,
    this.phone,
    this.coach,
    this.usaSwimmingId,
    this.profilePhotoUrl,
  });

  final String displayName;
  final int swimIqScore;
  final String highestCut;
  final String? team;
  final List<String> topEvents;
  final int? graduationYear;
  final String fileSafeName;
  final String? gpa;
  final String? website;
  final String? email;
  final String? phone;
  final String? coach;
  final String? usaSwimmingId;
  final String? profilePhotoUrl;
}

class RecruitingCardExportBar extends StatelessWidget {
  const RecruitingCardExportBar({
    super.key,
    required this.snapshot,
  });

  final RecruitingCardSnapshot snapshot;

  Future<Uint8List?> _loadPhotoBytes() async {
    final url = snapshot.profilePhotoUrl?.trim();
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 8),
          );
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  Future<Uint8List> _pdfBytes() async {
    final photo = await _loadPhotoBytes();
    final bytes = await RecruitingBusinessCardPdf.buildBytes(
      displayName: snapshot.displayName,
      swimIqScore: snapshot.swimIqScore,
      highestCut: snapshot.highestCut,
      team: snapshot.team,
      topEvents: snapshot.topEvents,
      graduationYear: snapshot.graduationYear,
      gpa: snapshot.gpa,
      website: snapshot.website,
      email: snapshot.email,
      phone: snapshot.phone,
      coach: snapshot.coach,
      usaSwimmingId: snapshot.usaSwimmingId,
      profilePhotoBytes: photo,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final export = OutlinedButton.icon(
          onPressed: () => _exportPdf(context),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: Text(compact ? 'PDF' : 'Export PDF'),
        );
        final printBtn = FilledButton.icon(
          onPressed: () => _printCard(context),
          icon: const Icon(Icons.print_outlined, size: 18),
          label: Text(compact ? 'Print' : 'Print'),
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
  }
}
