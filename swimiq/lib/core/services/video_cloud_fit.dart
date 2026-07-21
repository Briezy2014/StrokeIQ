import 'dart:typed_data';

import 'video_cloud_fit_stub.dart'
    if (dart.library.js_interop) 'video_cloud_fit_web.dart' as impl;

/// Live Edge Function is still ~25 MB until redeployed. Shrink phone clips
/// under this ceiling so Analyze works without bats/CLI.
const int kCloudAnalyzeSafeBytes = 22 * 1024 * 1024;

Future<Uint8List> fitVideoBytesForCloud(
  Uint8List bytes, {
  String? fileName,
  int maxBytes = kCloudAnalyzeSafeBytes,
}) {
  return impl.fitVideoBytesForCloudImpl(
    bytes,
    fileName: fileName,
    maxBytes: maxBytes,
  );
}

bool get canFitVideoBytesForCloud => impl.canFitVideoBytesForCloudImpl;
