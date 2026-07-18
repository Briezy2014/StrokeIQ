import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Printable wallet-sized recruiting card (3.5" × 2").
class RecruitingBusinessCardPdf {
  RecruitingBusinessCardPdf._();

  static const _cardNavy = PdfColor.fromInt(0xFF020812);
  static const _cardBlue = PdfColor.fromInt(0xFF0B2D4D);
  static const _cardBright = PdfColor.fromInt(0xFF0B5CAD);
  static const _accent = PdfColor.fromInt(0xFF009CFF);
  static const _statFill = PdfColor.fromInt(0xFF0C3D66);
  static const _statFillHighlight = PdfColor.fromInt(0xFF145A8C);
  static const _statBorder = PdfColor.fromInt(0xFF4DA3D9);
  static const _statLabel = PdfColor.fromInt(0xFFB8D9F0);

  static PdfPageFormat get pageFormat => PdfPageFormat(
        3.5 * PdfPageFormat.inch,
        2 * PdfPageFormat.inch,
        marginAll: 8,
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
    final eventOne = _pdfText(
      topEvents.isNotEmpty
          ? topEvents.first
          : 'Top event - log a meet result',
    );
    final eventTwo = _pdfText(
      topEvents.length > 1
          ? topEvents[1]
          : 'Second event - add another PB',
    );
    final teamLine = _pdfText(
      team?.trim().isNotEmpty == true ? team!.trim() : 'Add swim team in passport',
    );
    final gpaLine = _pdfText(
      gpa?.trim().isNotEmpty == true ? gpa!.trim() : 'Add GPA in passport',
    );
    final siteLine = _pdfText(
      _compactWebsite(
        website?.trim().isNotEmpty == true
            ? website!.trim()
            : 'Add recruiting site in passport',
      ),
    );
    final idLine = _pdfText(
      usaSwimmingId?.trim().isNotEmpty == true
          ? usaSwimmingId!.trim()
          : 'Add ID in passport',
    );
    final cutLine = _pdfText(
      highestCut.trim().isNotEmpty ? highestCut.trim() : 'Log a meet result',
    );

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [_cardNavy, _cardBlue, _cardBright],
              ),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                color: PdfColors.white,
                width: 0.5,
              ),
            ),
            padding: const pw.EdgeInsets.fromLTRB(7, 6, 7, 5),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _pdfText(displayName),
                            maxLines: 1,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 11,
                              font: pw.Font.helveticaBold(),
                            ),
                          ),
                          pw.Text(
                            teamLine,
                            maxLines: 1,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 7,
                              font: pw.Font.helvetica(),
                            ),
                          ),
                          if (graduationYear != null)
                            pw.Text(
                              'Class of $graduationYear',
                              style: pw.TextStyle(
                                color: _accent,
                                fontSize: 6.5,
                                font: pw.Font.helveticaBold(),
                              ),
                            ),
                          pw.SizedBox(height: 2),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                swimIqScore > 0 ? '$swimIqScore' : '-',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 18,
                                  font: pw.Font.helveticaBold(),
                                  height: 1,
                                ),
                              ),
                              pw.SizedBox(width: 3),
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 1),
                                child: pw.Text(
                                  'SwimIQ Score',
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontSize: 6.5,
                                    font: pw.Font.helveticaBold(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'Highest cut: $cutLine  |  USA: $idLine',
                            maxLines: 1,
                            style: pw.TextStyle(
                              color: _statLabel,
                              fontSize: 5.5,
                              font: pw.Font.helveticaBold(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Container(
                      width: 34,
                      height: 34,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: _statFill,
                        border: pw.Border.all(color: PdfColors.white, width: 0.8),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'PHOTO',
                        style: pw.TextStyle(
                          color: _statLabel,
                          fontSize: 4.5,
                          font: pw.Font.helveticaBold(),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Expanded(child: _statBox('Top event', eventOne, compact: true)),
                    pw.SizedBox(width: 3),
                    pw.Expanded(child: _statBox('2nd event', eventTwo, compact: true)),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Expanded(child: _statBox('GPA', gpaLine, compact: true)),
                    pw.SizedBox(width: 3),
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

  /// PDF standard fonts do not support alpha fills or most Unicode punctuation.
  static String _pdfText(String value) {
    return value
        .replaceAll('\u2014', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u2033', ' in');
  }

  static String _compactWebsite(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final withoutScheme = trimmed.replaceFirst(RegExp(r'^https?://'), '');
    if (withoutScheme.length <= 28) return withoutScheme;
    return '${withoutScheme.substring(0, 25)}...';
  }

  static pw.Widget _statBox(
    String label,
    String value, {
    bool highlight = false,
    bool compact = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: pw.BoxDecoration(
        color: highlight ? _statFillHighlight : _statFill,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: highlight ? _accent : _statBorder,
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
              color: _statLabel,
              fontSize: 5,
              font: pw.Font.helveticaBold(),
            ),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            value,
            maxLines: compact ? 2 : 1,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: compact ? 6 : 8.5,
              font: pw.Font.helveticaBold(),
            ),
          ),
        ],
      ),
    );
  }
}
