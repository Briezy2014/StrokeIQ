import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/race_log.dart';
import 'app_providers.dart';

final raceLogsProvider = FutureProvider.autoDispose<List<RaceLog>>((ref) async {
  final swimmerName = ref.watch(currentSwimmerNameProvider);
  if (swimmerName == null || swimmerName.isEmpty) {
    return [];
  }

  final service = ref.watch(raceLogServiceProvider);
  return service.fetchLogsForSwimmer(swimmerName);
});

final personalBestsProvider = FutureProvider.autoDispose<List<RaceLog>>((ref) async {
  final logs = await ref.watch(raceLogsProvider.future);
  final service = ref.watch(raceLogServiceProvider);
  return service.personalBests(logs);
});
