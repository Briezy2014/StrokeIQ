/// Swim time helpers ported from the existing Streamlit `app.py` logic.
class SwimTimeUtils {
  /// Converts swim time text into seconds.
  ///
  /// Accepts:
  /// - `35.43`
  /// - `1:24.32`
  /// - `5:31.43`
  static double swimTimeToSeconds(String timeText) {
    final trimmed = timeText.trim();
    if (trimmed.isEmpty) {
      throw FormatException('Time is required.');
    }

    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length != 2) {
        throw FormatException('Use M:SS.hh format.');
      }

      final minutes = int.parse(parts[0]);
      final seconds = double.parse(parts[1]);
      return double.parse(
        ((minutes * 60) + seconds).toStringAsFixed(2),
      );
    }

    return double.parse(double.parse(trimmed).toStringAsFixed(2));
  }

  /// Converts seconds into swim-time display text.
  static String secondsToSwimTime(double seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    if (minutes > 0) {
      final wholeSeconds = remaining.floor();
      final fraction = ((remaining - wholeSeconds) * 100).round();
      return '$minutes:${wholeSeconds.toString().padLeft(2, '0')}.'
          '${fraction.toString().padLeft(2, '0')}';
    }

    return seconds.toStringAsFixed(2);
  }
}
