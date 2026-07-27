import 'dart:convert';

import '../../data/models/swim_video_analysis.dart';
import '../../providers/swimmer_data_provider.dart';
import '../utils/passport_metrics.dart';

/// Compact Living Passport payload for QR / coach share links.
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
      };

  factory LivingPassportPayload.fromJson(Map<String, dynamic> json) {
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
      topTimes: snapshot.personalBests.take(3).toList(),
      latestTechniquePriorities:
          latest?.topPriorities.take(3).toList() ?? const [],
      generatedAtIso: DateTime.now().toUtc().toIso8601String(),
      latestClipLabel: clip,
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
    final root = Uri(
      scheme: origin.scheme.isEmpty ? 'https' : origin.scheme,
      host: origin.host.isEmpty ? 'swimiqapp.com' : origin.host,
      port: origin.hasPort ? origin.port : null,
      path: '/',
      queryParameters: {'lp': encode()},
    );
    return root.toString();
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
