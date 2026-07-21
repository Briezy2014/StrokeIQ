import 'dart:typed_data';

bool get canFitVideoBytesForCloudImpl => false;

Future<Uint8List> fitVideoBytesForCloudImpl(
  Uint8List bytes, {
  String? fileName,
  int maxBytes = 18 * 1024 * 1024,
}) async {
  if (bytes.lengthInBytes <= maxBytes) return bytes;
  throw StateError(
    'This video is too large for cloud analysis on this device. '
    'Open SwimIQ in Chrome on a computer, or trim the clip under '
    '${(maxBytes / (1024 * 1024)).round()} MB.',
  );
}
