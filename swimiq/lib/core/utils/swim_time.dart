/// Swim time parsing and formatting utilities matching the Streamlit app.
abstract final class SwimTime {
  /// Converts swim time text into seconds.
  ///
  /// Accepts `35.43`, `1:24.32`, or `5:31.43`.
  static double toSeconds(String timeText) {
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
      return double.parse(
        ((minutes * 60) + seconds).toStringAsFixed(2),
      );
    }

    return double.parse(double.parse(trimmed).toStringAsFixed(2));
  }

  /// Converts seconds into swim-time display format.
  static String fromSeconds(num? seconds) {
    if (seconds == null) return '—';

    final value = seconds is double ? seconds : seconds.toDouble();
    if (value.isNaN) return '—';

    final minutes = value ~/ 60;
    final remaining = value % 60;

    if (minutes > 0) {
      final remainingStr = remaining.toStringAsFixed(2).padLeft(5, '0');
      return '$minutes:$remainingStr';
    }

    return value.toStringAsFixed(2);
  }

  /// Parses a value that may be stored as a string or number in Supabase.
  static double? parseStoredTime(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.contains(':')) {
        try {
          return toSeconds(trimmed);
        } on FormatException {
          return null;
        }
      }
      return double.tryParse(trimmed);
    }
    return null;
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

  /// Builds seconds from structured minute/second/tenth/hundredth parts.
  static double fromParts({
    int minutes = 0,
    required int seconds,
    required int tenths,
    required int hundredths,
  }) {
    if (minutes < 0) {
      throw const FormatException('Minutes cannot be negative.');
    }
    if (seconds < 0 || seconds > 59) {
      throw const FormatException('Seconds must be between 0 and 59.');
    }
    if (tenths < 0 || tenths > 9) {
      throw const FormatException('Tenths must be a single digit (0-9).');
    }
    if (hundredths < 0 || hundredths > 9) {
      throw const FormatException('Hundredths must be a single digit (0-9).');
    }

    final total = (minutes * 60) + seconds + (tenths / 10) + (hundredths / 100);
    return double.parse(total.toStringAsFixed(2));
  }
}
