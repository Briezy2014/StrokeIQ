import 'dart:typed_data';

import '../../data/models/swim_pose_metrics.dart';

bool get isPoseAnalysisSupported => false;

Future<SwimPoseMetrics?> analyzeVideoBytesImpl(
  Uint8List bytes, {
  String? fileName,
}) async {
  return null;
}
