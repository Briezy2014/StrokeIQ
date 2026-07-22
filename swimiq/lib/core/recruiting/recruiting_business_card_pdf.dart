import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'recruiting_card_insights.dart';

/// Printable wallet-sized recruiting card (3.5" × 2") for coaches.
class RecruitingBusinessCardPdf {
  RecruitingBusinessCardPdf._();

  static const _navy = PdfColor.fromInt(0xFF041526);
  static const _mid = PdfColor.fromInt(0xFF0B3D6E);
  static const _deep = PdfColor.fromInt(0xFF0B5CAD);
  static const _accent = PdfColor.fromInt(0xFF38B6FF);
  static const _panel = PdfColor.fromInt(0xFF0A2F52);
  static const _muted = PdfColor.fromInt(0xFFB8D9F0);

  static PdfPageFormat get pageFormat => PdfPageFormat(
        3.5 * PdfPageFormat.inch,
        2.2 * PdfPageFormat.inch,
        marginAll: 6,
      );

  static Future<List<int>> buildBytes({
    required String displayName,
    required int swimIqScore,
    required String highestCut,
    required String? team,
    required List<String> topEvents,
    required int? graduationYear,
    String? gpa,
    String? website,
    String? email,
    String? phone,
    String? coach,
    String? usaSwimmingId,
    Uint8List? profilePhotoBytes,
  }) async {
    final insights = RecruitingCardInsights.from(
      highestCut: highestCut,
      topEvents: topEvents,
      swimIqScore: swimIqScore,
    );
    final cutValue = _cutDisplayValue(highestCut);
    final eventOne = _eventWithCut(
      topEvents.isNotEmpty ? topEvents.first : 'Add top PB',
      cutValue,
      allowCut: topEvents.isNotEmpty,
    );
    final eventTwo = _eventWithCut(
      topEvents.length > 1 ? topEvents[1] : 'Add 2nd PB',
      cutValue,
      allowCut: topEvents.length > 1,
    );
    final teamLine = _pdfText(
      team?.trim().isNotEmpty == true ? team!.trim() : 'Add club / team',
    );
    final gradLine = graduationYear != null
        ? 'Class of $graduationYear'
        : 'Grad year';
    final scoreText = swimIqScore > 0 ? '$swimIqScore' : '-';
    final nameLine = _pdfText(
      displayName.trim().isEmpty ? 'Add athlete name' : displayName.trim(),
    );
    final websiteLine = _pdfText(
      website?.trim().isNotEmpty == true ? website!.trim() : 'Add website',
    );
    final emailLine = _pdfText(
      email?.trim().isNotEmpty == true ? email!.trim() : 'Add email',
    );
    final phoneLine = _pdfText(
      phone?.trim().isNotEmpty == true ? phone!.trim() : 'Add phone',
    );
    final coachLine = _pdfText(
      coach?.trim().isNotEmpty == true ? coach!.trim() : 'Add coach',
    );
    final gpaLine =
        gpa?.trim().isNotEmpty == true ? _pdfText(gpa!.trim()) : null;

    pw.ImageProvider? photo;
    if (profilePhotoBytes != null && profilePhotoBytes.isNotEmpty) {
      try {
        photo = pw.MemoryImage(profilePhotoBytes);
      } catch (_) {
        photo = null;
      }
    }

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [_navy, _mid, _deep],
              ),
              borderRadius: pw.BorderRadius.circular(7),
              border: pw.Border.all(color: PdfColors.white, width: 0.7),
            ),
            padding: const pw.EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'SWIMIQ',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 7,
                        font: pw.Font.helveticaBold(),
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _panel,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: _accent, width: 0.4),
                      ),
                      child: pw.Text(
                        _pdfText(insights.achievementBadge).toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 6,
                          font: pw.Font.helveticaBold(),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 52,
                      height: 52,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: _panel,
                        border: pw.Border.all(
                          color: PdfColors.white,
                          width: 1.2,
                        ),
                      ),
                      alignment: pw.Alignment.center,
                      child: photo != null
                          ? pw.ClipOval(
                              child: pw.Image(
                                photo,
                                width: 52,
                                height: 52,
                                fit: pw.BoxFit.cover,
                              ),
                            )
                          : pw.Text(
                              'PHOTO',
                              style: pw.TextStyle(
                                color: _muted,
                                fontSize: 6,
                                font: pw.Font.helveticaBold(),
                              ),
                            ),
                    ),
                    pw.SizedBox(width: 7),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            nameLine,
                            maxLines: 1,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 12,
                              font: pw.Font.helveticaBold(),
                            ),
                          ),
                          pw.Text(
                            '$gradLine  |  $teamLine',
                            maxLines: 1,
                            style: pw.TextStyle(
                              color: _muted,
                              fontSize: 6.5,
                              font: pw.Font.helveticaBold(),
                            ),
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'Coach: $coachLine',
                            maxLines: 1,
                            style: pw.TextStyle(
                              color: _muted,
                              fontSize: 6.5,
                              font: pw.Font.helveticaBold(),
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                scoreText,
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 15,
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
                                    fontSize: 5.5,
                                    font: pw.Font.helveticaBold(),
                                  ),
                                ),
                              ),
                              if (gpaLine != null) ...[
                                pw.SizedBox(width: 5),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1.5,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: _panel,
                                    borderRadius: pw.BorderRadius.circular(3),
                                  ),
                                  child: pw.Text(
                                    'GPA $gpaLine',
                                    style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontSize: 6,
                                      font: pw.Font.helveticaBold(),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              websiteLine,
                              maxLines: 1,
                              style: pw.TextStyle(
                                color: _muted,
                                fontSize: 6,
                                font: pw.Font.helveticaBold(),
                              ),
                            ),
                            pw.Text(
                              emailLine,
                              maxLines: 1,
                              style: pw.TextStyle(
                                color: _muted,
                                fontSize: 6,
                                font: pw.Font.helveticaBold(),
                              ),
                            ),
                            pw.Text(
                              phoneLine,
                              maxLines: 1,
                              style: pw.TextStyle(
                                color: _muted,
                                fontSize: 6,
                                font: pw.Font.helveticaBold(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Expanded(
                        flex: 6,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'TOP TIMES',
                              style: pw.TextStyle(
                                color: _muted,
                                fontSize: 5.5,
                                font: pw.Font.helveticaBold(),
                                letterSpacing: 0.4,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            _pbRow('1', eventOne.event, cut: eventOne.cut),
                            pw.SizedBox(height: 2),
                            _pbRow('2', eventTwo.event, cut: eventTwo.cut),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF03101F),
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: _accent, width: 0.4),
                  ),
                  child: pw.Text(
                    _pdfText(insights.highlight),
                    maxLines: 1,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 7,
                      font: pw.Font.helveticaBold(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  static String _cutDisplayValue(String highestCut) {
    final cut = highestCut.trim();
    if (cut.isEmpty ||
        cut.toLowerCase().contains('log') ||
        cut.toLowerCase().contains('setup') ||
        cut.toLowerCase().contains('no motivational')) {
      return '';
    }
    final match = RegExp(r'\b(AAAA|AAA|AA|A|BB|B)\b', caseSensitive: false)
        .firstMatch(cut);
    if (match != null) return match.group(1)!.toUpperCase();
    return _pdfText(cut);
  }

  static ({String event, String? cut}) _eventWithCut(
    String event,
    String cutValue, {
    bool allowCut = true,
  }) {
    final trimmed = _pdfText(event.trim());
    if (!allowCut || cutValue.isEmpty) return (event: trimmed, cut: null);
    if (RegExp(r'\b(AAAA|AAA|AA|A|BB|B)\b').hasMatch(trimmed)) {
      return (event: trimmed, cut: null);
    }
    return (event: trimmed, cut: cutValue);
  }

  static pw.Widget _pbRow(String label, String value, {String? cut}) {
    return pw.Row(
      children: [
        pw.Container(
          width: 9,
          height: 9,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: _panel,
            borderRadius: pw.BorderRadius.circular(2),
          ),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 5.5,
              font: pw.Font.helveticaBold(),
            ),
          ),
        ),
        pw.SizedBox(width: 3),
        pw.Expanded(
          child: pw.Text(
            value,
            maxLines: 1,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 7,
              font: pw.Font.helveticaBold(),
            ),
          ),
        ),
        if (cut != null && cut.isNotEmpty) ...[
          pw.SizedBox(width: 3),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: pw.BoxDecoration(
              color: _panel,
              borderRadius: pw.BorderRadius.circular(2),
              border: pw.Border.all(color: _accent, width: 0.5),
            ),
            child: pw.Text(
              cut,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 7,
                font: pw.Font.helveticaBold(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _pdfText(String value) {
    return value
        .replaceAll('\u2014', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u2033', '"');
  }
}
