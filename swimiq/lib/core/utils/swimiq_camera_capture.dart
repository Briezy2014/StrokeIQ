import 'package:flutter/material.dart';

import 'swimiq_captured_photo.dart';
import 'swimiq_camera_capture_mobile.dart'
    if (dart.library.js_interop) 'swimiq_camera_capture_web.dart' as camera_impl;

/// Opens the device camera (webcam on Chrome, native camera on phones).
Future<SwimIqCapturedPhoto?> captureSwimIqPhoto(BuildContext context) =>
    camera_impl.captureSwimIqPhoto(context);
