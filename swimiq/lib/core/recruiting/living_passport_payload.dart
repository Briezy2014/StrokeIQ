import 'dart:convert';

import '../../data/models/swim_video_analysis.dart';
import '../../providers/swimmer_data_provider.dart';
import '../utils/passport_metrics.dart';

/// One compact Power Index factor for the coach Living Passport chart.
class LivingPassportPowerFactor {
  const LivingPassportPowerFactor({
    required this.id,
    required this.label,
    required this.score,
    required this.weightPercent,
  });

  final String id;
  final String label;
  final int score;
  final int weightPercent;

  Map<String, dynamic> toJson() => {
        'i': id,
        'l': label,
        's': score,
        'w': weightPercent,
      };

  factory LivingPassportPowerFactor.fromJson(Map<String, dynamic> json) {
    return LivingPassportPowerFactor(
      id: json['i']?.toString() ?? 'factor',
      label: json['l']?.toString() ?? 'Factor',
      score: int.tryParse('${json['s']}') ?? 0,
      weightPercent: int.tryParse('${json['w']}') ?? 0,
    );
  }
}

/// Compact Living Passport payload for QR / coach share links.
///
/// Intentionally small so phone cameras can scan the QR reliably. The public
/// coach screen renders charts from these embedded fields — it does not open
/// the logged-in athlete dashboard.
class LivingPassportPayload {
  const LivingPassportPayload({
    required this.displayName,
    required this.swimIqScore,
    required this.highestCut,
    required this.readiness,
    required this.nextMeet,
    required this.powerIndexLine,
    required this.topTimes,
    required this.latestTechniquePriorities,
    required this.generatedAtIso,
    this.latestClipLabel,
    this.powerIndexScore,
    this.powerIndexLabel,
    this.powerFactors = const [],
    this.strongestEvent,
    this.currentFocus,
    this.usaStandardsSummary,
  });

  final String displayName;
  final int swimIqScore;
  final String highestCut;
  final String readiness;
  final String nextMeet;
  final String powerIndexLine;
  final List<String> topTimes;
  final List<String> latestTechniquePriorities;
  final String generatedAtIso;
  final String? latestClipLabel;
  final int? powerIndexScore;
  final String? powerIndexLabel;
  final List<LivingPassportPowerFactor> powerFactors;
  final String? strongestEvent;
  final String? currentFocus;
  final String? usaStandardsSummary;

  int get resolvedPowerIndexScore {
    if (powerIndexScore != null) return powerIndexScore!;
    final match = RegExp(r'(\d+)\s*/\s*100').firstMatch(powerIndexLine);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  String get resolvedPowerIndexLabel {
    final explicit = powerIndexLabel?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final parts = powerIndexLine.split('·');
    if (parts.length >= 2) return parts[1].trim();
    return powerIndexLine;
  }

  Map<String, dynamic> toJson() => {
        'n': displayName,
        's': swimIqScore,
        'c': highestCut,
        'r': readiness,
        'm': nextMeet,
        'p': powerIndexLine,
        't': topTimes,
        'v': latestTechniquePriorities,
        'g': generatedAtIso,
        if (latestClipLabel != null && latestClipLabel!.trim().isNotEmpty)
          'l': latestClipLabel,
        if (powerIndexScore != null) 'ps': powerIndexScore,
        if (powerIndexLabel != null && powerIndexLabel!.trim().isNotEmpty)
          'pl': powerIndexLabel,
        if (powerFactors.isNotEmpty)
          'pf': powerFactors.map((f) => f.toJson()).toList(),
        if (strongestEvent != null && strongestEvent!.trim().isNotEmpty)
          'se': strongestEvent,
        if (currentFocus != null && currentFocus!.trim().isNotEmpty)
          'f': currentFocus,
        if (usaStandardsSummary != null &&
            usaStandardsSummary!.trim().isNotEmpty)
          'u': _shortStandards(usaStandardsSummary!),
      };

  factory LivingPassportPayload.fromJson(Map<String, dynamic> json) {
    final factorsRaw = json['pf'];
    final factors = <LivingPassportPowerFactor>[];
    if (factorsRaw is List) {
      for (final item in factorsRaw) {
        if (item is Map<String, dynamic>) {
          factors.add(LivingPassportPowerFactor.fromJson(item));
        } else if (item is Map) {
          factors.add(
            LivingPassportPowerFactor.fromJson(
              item.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }

    return LivingPassportPayload(
      displayName: json['n']?.toString() ?? 'Athlete',
      swimIqScore: int.tryParse('${json['s']}') ?? 0,
      highestCut: json['c']?.toString() ?? '-',
      readiness: json['r']?.toString() ?? '-',
      nextMeet: json['m']?.toString() ?? PassportMetrics.noUpcomingMeetLabel,
      powerIndexLine: json['p']?.toString() ?? '-',
      topTimes: (json['t'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      latestTechniquePriorities:
          (json['v'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      generatedAtIso: json['g']?.toString() ?? '',
      latestClipLabel: json['l']?.toString(),
      powerIndexScore: int.tryParse('${json['ps']}'),
      powerIndexLabel: json['pl']?.toString(),
      powerFactors: factors,
      strongestEvent: json['se']?.toString(),
      currentFocus: json['f']?.toString(),
      usaStandardsSummary: json['u']?.toString(),
    );
  }

  static LivingPassportPayload fromData({
    required SwimmerData data,
    required String swimmer,
  }) {
    final snapshot = data.passportSnapshot(swimmer);
    final latest = _latestAnalysis(data.userFacingVideoAnalyses);
    final clip = _clipLabelForAnalysis(data, latest);
    final power = snapshot.powerIndex;
    return LivingPassportPayload(
      displayName: snapshot.displayName,
      swimIqScore: snapshot.swimIqScore,
      highestCut: snapshot.highestCut,
      readiness: snapshot.readiness,
      nextMeet: snapshot.nextMeet,
      powerIndexLine: power.hasEnoughData
          ? '${power.score} / 100 · ${power.label}'
          : 'Not calculated',
      topTimes: snapshot.personalBests.take(5).toList(),
      latestTechniquePriorities:
          latest?.topPriorities.take(3).toList() ?? const [],
      generatedAtIso: DateTime.now().toUtc().toIso8601String(),
      latestClipLabel: clip,
      powerIndexScore: power.hasEnoughData ? power.score : null,
      powerIndexLabel: power.hasEnoughData ? power.label : null,
      powerFactors: power.hasEnoughData
          ? power.factors
              .take(5)
              .map(
                (f) => LivingPassportPowerFactor(
                  id: f.id,
                  label: f.label,
                  score: f.componentScore,
                  weightPercent: f.weightPercent,
                ),
              )
              .toList()
          : const [],
      strongestEvent: power.strongestEvent,
      currentFocus: snapshot.currentFocus,
      usaStandardsSummary: snapshot.usaStandardsSummary,
    );
  }

  String encode() {
    final raw = jsonEncode(toJson());
    return base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
  }

  static LivingPassportPayload? tryDecode(String? encoded) {
    if (encoded == null || encoded.trim().isEmpty) return null;
    try {
      var padded = encoded.trim();
      final mod = padded.length % 4;
      if (mod > 0) padded = padded.padRight(padded.length + (4 - mod), '=');
      final json = jsonDecode(utf8.decode(base64Url.decode(padded)))
          as Map<String, dynamic>;
      return LivingPassportPayload.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  String shareUrl({Uri? base}) {
    final origin = base ?? Uri.base;
    var scheme = origin.scheme.isEmpty ? 'https' : origin.scheme;
    var host = origin.host.isEmpty ? 'swimiqapp.com' : origin.host;
    // GoDaddy HTTPS can still show the Coming Soon page — coach QR links use
    // http so scans open the real Flutter Living Passport view.
    if (host == 'swimiqapp.com' || host == 'www.swimiqapp.com') {
      scheme = 'http';
      host = 'swimiqapp.com';
    }
    final root = Uri(
      scheme: scheme,
      host: host,
      port: origin.hasPort && host != 'swimiqapp.com' ? origin.port : null,
      path: '/',
      queryParameters: {'lp': encode()},
    );
    return root.toString();
  }

  static String _shortStandards(String full) {
    final first = full.split('\n').first.trim();
    if (first.length <= 120) return first;
    return '${first.substring(0, 117)}...';
  }

  static SwimVideoAnalysis? _latestAnalysis(List<SwimVideoAnalysis> analyses) {
    if (analyses.isEmpty) return null;
    final sorted = [...analyses]
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return sorted.first;
  }

  static String? _clipLabelForAnalysis(
    SwimmerData data,
    SwimVideoAnalysis? analysis,
  ) {
    if (analysis == null) return null;
    final videoId = analysis.swimVideoId;
    if (videoId != null) {
      for (final video in data.userFacingVideos) {
        if (video.id == videoId) return video.displayTitle;
      }
    }
    return 'Latest AI analysis';
  }
}
