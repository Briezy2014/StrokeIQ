class SwimTime {
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

  static String fromSeconds(dynamic seconds) {
    try {
      final value = double.parse(seconds.toString());
      final minutes = value ~/ 60;
      final remaining = value % 60;

      if (minutes > 0) {
        return '$minutes:${remaining.toStringAsFixed(2).padLeft(5, '0')}';
      }
      return value.toStringAsFixed(2);
    } catch (_) {
      return '—';
    }
  }
}
