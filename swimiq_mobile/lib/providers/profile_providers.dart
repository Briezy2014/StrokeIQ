import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/swimmer_profile.dart';
import 'app_providers.dart';

final swimmerProfileProvider = FutureProvider.autoDispose<SwimmerProfile?>((ref) async {
  final swimmerName = ref.watch(currentSwimmerNameProvider);
  if (swimmerName == null || swimmerName.isEmpty) {
    return null;
  }

  final profileService = ref.watch(profileServiceProvider);
  return profileService.getProfileBySwimmerName(swimmerName);
});
