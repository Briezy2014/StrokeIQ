/// Swim time parsing and formatting — mirrors the Streamlit reference app.
abstract final class SwimTime {
  /// Converts swim time text into seconds.
  ///
  /// Accepts: `35.43`, `1:24.32`, `5:31.43`
  static double toSeconds(String timeText) {
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

  /// Converts seconds into swim-time display format.
  static String fromSeconds(double seconds) {
    final total = seconds;
    final minutes = total ~/ 60;
    final remaining = total % 60;

    if (minutes > 0) {
      final secStr = remaining.toStringAsFixed(2).padLeft(5, '0');
      return '$minutes:$secStr';
    }

    return remaining.toStringAsFixed(2);
  }

  /// Returns true if [timeText] can be parsed as a swim time.
  static bool isValid(String timeText) {
    try {
      toSeconds(timeText);
      return true;
    } on FormatException {
      return false;
    }
  }
}
