import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/swimiq_camera_capture.dart';
import 'package:swimiq/core/utils/swimiq_video_camera_capture.dart';

void main() {
  test('shared photo and video camera helpers are exported', () {
    expect(captureSwimIqPhoto, isNotNull);
    expect(captureSwimIqVideo, isNotNull);
  });
}
