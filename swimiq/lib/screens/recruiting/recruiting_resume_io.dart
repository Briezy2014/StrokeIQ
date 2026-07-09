import 'dart:io';

Future<void> recruitingResumeFileWriter(String path, String text) async {
  await File(path).writeAsString(text);
}
