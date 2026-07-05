import '../../data/models/swimmer_profile.dart';

class SwimIqGender {
  SwimIqGender._();

  static String standardsGender(SwimmerProfile? profile) {
    final raw = profile?.gender?.trim();
    if (raw == null || raw.isEmpty) return 'Girls';
    final lower = raw.toLowerCase();
    if (lower.startsWith('m') || lower.startsWith('b')) return 'Boys';
    return 'Girls';
  }
}
