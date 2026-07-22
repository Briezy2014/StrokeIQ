import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'swimiq_captured_photo.dart';

/// Native/mobile camera via image_picker.
Future<SwimIqCapturedPhoto?> captureSwimIqPhoto(BuildContext context) async {
  final picker = ImagePicker();
  final photo = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 85,
    maxWidth: 2400,
  );
  if (photo == null) return null;
  return SwimIqCapturedPhoto(
    bytes: await photo.readAsBytes(),
    fileName: photo.name,
  );
}
