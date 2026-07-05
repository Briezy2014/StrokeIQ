/// Normalizes stroke labels across race logs, videos, and standards.
class SwimStrokeUtils {
  SwimStrokeUtils._();

  static String canonical(String? stroke) {
    final value = stroke?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return '';
    if (value == 'fly' || value.contains('butterfly')) return 'Butterfly';
    if (value == 'free' || value.contains('freestyle')) return 'Freestyle';
    if (value == 'back' || value.contains('backstroke')) return 'Backstroke';
    if (value == 'breast' || value.contains('breaststroke')) {
      return 'Breaststroke';
    }
    if (value == 'im') return 'IM';
    return stroke!.trim();
  }

  static bool matches(String? left, String? right) {
    final a = canonical(left);
    final b = canonical(right);
    if (a.isEmpty || b.isEmpty) return false;
    return a == b;
  }
}
