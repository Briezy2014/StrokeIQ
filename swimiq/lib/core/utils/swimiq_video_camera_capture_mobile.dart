import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'swimiq_captured_video.dart';

/// Native/mobile video recording via image_picker.
Future<SwimIqCapturedVideo?> captureSwimIqVideo(BuildContext context) async {
  final picker = ImagePicker();
  final video = await picker.pickVideo(source: ImageSource.camera);
  if (video == null) return null;
  return SwimIqCapturedVideo(
    bytes: await video.readAsBytes(),
    fileName: video.name,
  );
}
