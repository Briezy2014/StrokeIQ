import 'dart:typed_data';

import '../../data/models/swim_pose_metrics.dart';

/// Web builds use Gemini for video coaching; on-device pose is optional.
bool get isPoseAnalysisSupported => false;

Future<SwimPoseMetrics?> analyzeVideoBytesImpl(
  Uint8List bytes, {
  String? fileName,
}) async {
  return null;
}
