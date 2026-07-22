import 'dart:typed_data';

/// Photo captured from device camera or webcam.
class SwimIqCapturedPhoto {
  const SwimIqCapturedPhoto({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}
