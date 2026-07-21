import 'dart:typed_data';

import 'video_cloud_fit_stub.dart'
    if (dart.library.js_interop) 'video_cloud_fit_web.dart' as impl;

/// Live Edge Function (sync-v9) accepts ≤25 MB, but the reliable path is the
/// ≤12 MB inline Gemini upload. Shrink phone clips under this ceiling so
/// Analyze avoids the flaky File API path until sync-v11 is redeployed.
const int kCloudAnalyzeSafeBytes = 10 * 1024 * 1024;

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
