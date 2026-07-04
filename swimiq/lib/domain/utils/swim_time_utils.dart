/// Swim time parsing and formatting — ported from the Streamlit helpers.
class SwimTimeUtils {
  SwimTimeUtils._();

  /// Converts swim time text into seconds.
  ///
  /// Accepts `35.43`, `1:24.32`, or `5:31.43`.
  static double swimTimeToSeconds(String timeText) {
    final trimmed = timeText.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Time is required.');
    }

    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length != 2) {
        throw const FormatException('Use M:SS.hh format.');
      }
      final minutes = int.parse(parts[0]);
      final seconds = double.parse(parts[1]);
      return double.parse(((minutes * 60) + seconds).toStringAsFixed(2));
    }

    return double.parse(double.parse(trimmed).toStringAsFixed(2));
  }

  /// Converts seconds into swim-time display format.
  static String secondsToSwimTime(num? seconds) {
    if (seconds == null) return '';

    final value = seconds.toDouble();
    final minutes = value ~/ 60;
    final remaining = value % 60;

    if (minutes > 0) {
      final whole = remaining.truncate();
      final fraction = ((remaining - whole) * 100).round();
      return '$minutes:${whole.toString().padLeft(2, '0')}.'
          '${fraction.toString().padLeft(2, '0')}';
    }

    return value.toStringAsFixed(2);
  }
}
