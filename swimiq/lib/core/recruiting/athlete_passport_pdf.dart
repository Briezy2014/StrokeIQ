import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/passport_metrics.dart';
import '../../data/models/swimmer_profile.dart';

/// Full Athlete Passport PDF — printable coach/parent/recruiting packet.
class AthletePassportPdf {
  AthletePassportPdf._();

  static Future<List<int>> buildBytes({
    required PassportSnapshot snapshot,
    required SwimmerProfile? profile,
    required String displayName,
  }) async {
    final doc = pw.Document();
    final power = snapshot.powerIndex;
    final name = displayName.trim().isEmpty ? snapshot.displayName : displayName;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            'SWIMIQ ATHLETE PASSPORT',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            name.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Text(
            _subtitle(profile),
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 6),
          pw.Divider(thickness: 2, color: PdfColors.blue800),
          _section('Athlete Status', [
            _line('SwimIQ Score', snapshot.swimIqScore > 0
                ? '${snapshot.swimIqScore}'
                : 'Not calculated yet'),
            _line('Readiness', snapshot.readiness),
            _line('Current focus', snapshot.currentFocus),
            _line('Highest USA cut', snapshot.highestCut),
            _line('Upcoming meet', snapshot.nextMeet),
            if (snapshot.swimIqExplanation.trim().isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  snapshot.swimIqExplanation,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
          ]),
          _section('Identity & Academics', [
            _line('Preferred name', profile?.preferredName),
            _line('Graduation year', profile?.graduationYear?.toString()),
            _line('Club / team', profile?.team),
            _line('High school', profile?.school),
            _line('Coach', profile?.coachName),
            _line('USA Swimming ID', profile?.usaSwimmingId),
            _line('Primary stroke', profile?.primaryStroke),
            _line('Favorite event', profile?.favoriteEvent),
            _line('GPA', profile?.gpa),
            _line('Website', profile?.athleteWebsite),
            _line('Email', profile?.athleteEmail),
            _line('Phone', profile?.athletePhone),
            _line('Recruiting status', profile?.recruitingStatus),
            _line('Intended major', profile?.intendedMajor),
          ]),
          _section('Power Index', [
            if (!power.hasEnoughData)
              pw.Text(
                power.missingDataHint ??
                    'Add official PBs plus birthday and gender to calculate.',
                style: const pw.TextStyle(fontSize: 10),
              )
            else ...[
              pw.Text(
                '${power.score} / 100 · ${power.label}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (power.strongestEvent != null)
                pw.Text(
                  'Strongest event: ${power.strongestEvent}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              pw.SizedBox(height: 4),
              ...power.factors.map(
                (factor) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${factor.label} (${factor.weightPercent}%) · '
                        'score ${factor.componentScore} → '
                        '+${factor.weightedPoints.toStringAsFixed(1)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        factor.explanation,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ]),
          _section('Top Times', [
            if (snapshot.personalBests.isEmpty)
              pw.Text('No personal bests logged yet.')
            else
              ...snapshot.personalBests.take(8).map(
                    (line) => pw.Bullet(text: line),
                  ),
          ]),
          _section('Goals', [
            if (snapshot.goalLines.isEmpty)
              pw.Text('No active goals yet.')
            else
              ...snapshot.goalLines.take(6).map(
                    (line) => pw.Bullet(text: line),
                  ),
          ]),
          _section('Coaching Snapshot', [
            _line('Videos uploaded', '${snapshot.videoCount}'),
            _line('AI analyses', '${snapshot.analysisCount}'),
            if (snapshot.latestAnalysisEvent != null)
              _line('Latest analysis event', snapshot.latestAnalysisEvent),
            if (snapshot.latestAnalysisSummary.trim().isNotEmpty)
              pw.Text(
                snapshot.latestAnalysisSummary,
                style: const pw.TextStyle(fontSize: 9),
              ),
            _line('Next focus', snapshot.nextFocus),
          ]),
          _section('USA Standards', [
            pw.Text(
              snapshot.usaStandardsSummary,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ]),
          pw.SizedBox(height: 16),
          pw.Text(
            'Generated by SwimIQ · For coaches, parents, and recruiting packets · '
            'swimiqapp.com',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static String _subtitle(SwimmerProfile? profile) {
    final parts = <String>[
      if (profile?.graduationYear != null) 'Class of ${profile!.graduationYear}',
      if (profile?.team?.trim().isNotEmpty == true) profile!.team!.trim(),
      if (profile?.primaryStroke?.trim().isNotEmpty == true)
        profile!.primaryStroke!.trim(),
    ];
    return parts.isEmpty ? 'Athlete Passport' : parts.join(' · ');
  }

  static pw.Widget _section(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 12),
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
            letterSpacing: 0.6,
          ),
        ),
        pw.SizedBox(height: 4),
        ...children,
      ],
    );
  }

  static pw.Widget _line(String label, String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text('$label: $text', style: const pw.TextStyle(fontSize: 10)),
    );
  }
}
