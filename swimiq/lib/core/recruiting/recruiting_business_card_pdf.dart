import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Printable wallet-sized recruiting card (3.5" × 2").
class RecruitingBusinessCardPdf {
  RecruitingBusinessCardPdf._();

  static PdfPageFormat get pageFormat => PdfPageFormat(
        3.5 * PdfPageFormat.inch,
        2 * PdfPageFormat.inch,
        marginAll: 10,
      );

  static Future<List<int>> buildBytes({
    required String displayName,
    required int swimIqScore,
    required String highestCut,
    required String? team,
    required String? gpa,
    required String? website,
    required List<String> topEvents,
    required int? graduationYear,
    required String? usaSwimmingId,
  }) async {
    final doc = pw.Document();
    final eventOne = topEvents.isNotEmpty
        ? topEvents.first
        : 'Top event — log a meet result';
    final eventTwo = topEvents.length > 1
        ? topEvents[1]
        : 'Second event — add another PB';
    final teamLine =
        team?.trim().isNotEmpty == true ? team!.trim() : 'Add swim team in passport';
    final gpaLine =
        gpa?.trim().isNotEmpty == true ? gpa!.trim() : 'Add GPA in passport';
    final siteLine = website?.trim().isNotEmpty == true
        ? website!.trim()
        : 'Add recruiting site in passport';
    final idLine = usaSwimmingId?.trim().isNotEmpty == true
        ? usaSwimmingId!.trim()
        : 'Add ID in passport';

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [
                  PdfColor.fromInt(0xFF020812),
                  PdfColor.fromInt(0xFF0B2D4D),
                  PdfColor.fromInt(0xFF0B5CAD),
                ],
              ),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                color: PdfColors.white,
                width: 0.5,
              ),
            ),
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            displayName,
                            maxLines: 1,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            teamLine,
                            maxLines: 1,
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 8,
                            ),
                          ),
                          if (graduationYear != null)
                            pw.Text(
                              'Class of $graduationYear',
                              style: pw.TextStyle(
                                color: PdfColor.fromInt(0xFF009CFF),
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'USA Swimming',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          idLine,
                          style: pw.TextStyle(
                            color: PdfColor.fromInt(0xFF009CFF),
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _statBox(
                        'SwimIQ Score',
                        swimIqScore > 0 ? '$swimIqScore' : '—',
                        highlight: true,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: _statBox('Highest Cut', highestCut),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Expanded(child: _statBox('Top event', eventOne, compact: true)),
                    pw.SizedBox(width: 6),
                    pw.Expanded(child: _statBox('2nd event', eventTwo, compact: true)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Expanded(child: _statBox('GPA', gpaLine, compact: true)),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: _statBox('Recruiting site', siteLine, compact: true),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _statBox(
    String label,
    String value, {
    bool highlight = false,
    bool compact = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: pw.BoxDecoration(
        color: highlight
            ? PdfColor.fromInt(0x33FFFFFF)
            : PdfColor.fromInt(0x1AFFFFFF),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: highlight
              ? PdfColor.fromInt(0x88009CFF)
              : PdfColor.fromInt(0x33FFFFFF),
          width: 0.5,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            maxLines: 1,
            style: pw.TextStyle(
              color: PdfColor.fromInt(0xBFFFFFFF),
              fontSize: 5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            value,
            maxLines: compact ? 2 : 1,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: compact ? 6 : 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
